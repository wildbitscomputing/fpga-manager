#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "firmware_image.h"
#include "firmware_update_engine.h"
#include "firmware_update_layout.h"

namespace {

using firmware_update::BoardRevision;
using firmware_update::BootDecision;
using firmware_update::FirmwareStorage;
using firmware_update::StorageResult;
using firmware_update::UpdateCheckpoint;
using firmware_update::UpdateResult;
using firmware_update::UpdateState;

bool expect(bool condition, const char* message)
{
    if (!condition) {
        std::fprintf(stderr, "update-engine test failed: %s\n", message);
    }
    return condition;
}

std::vector<uint8_t> read_file(const char* path)
{
    std::ifstream input(path, std::ios::binary);
    return std::vector<uint8_t>((std::istreambuf_iterator<char>(input)),
                                std::istreambuf_iterator<char>());
}

class SimulatedFlash : public FirmwareStorage {
  public:
    SimulatedFlash() : bytes_(firmware_update::kFlashSize, 0xff) {}
    explicit SimulatedFlash(const std::vector<uint8_t>& bytes) : bytes_(bytes) {}

    const uint8_t* read(uint32_t offset, size_t length) override
    {
        if (offset > bytes_.size() || length > bytes_.size() - offset) {
            return nullptr;
        }
        return bytes_.data() + offset;
    }

    StorageResult erase_sector(uint32_t offset) override
    {
        if ((offset & (firmware_update::kFlashSectorSize - 1)) != 0 ||
            offset > bytes_.size() - firmware_update::kFlashSectorSize) {
            return StorageResult::Error;
        }
        if (interrupt_here()) {
            std::fill_n(bytes_.begin() + offset,
                        firmware_update::kFlashSectorSize / 2, 0xff);
            return StorageResult::Interrupted;
        }
        std::fill_n(bytes_.begin() + offset,
                    firmware_update::kFlashSectorSize, 0xff);
        return interrupt_here() ? StorageResult::Interrupted
                                : StorageResult::Ok;
    }

    StorageResult program_page(
        uint32_t offset,
        const uint8_t data[firmware_update::kFlashPageSize]) override
    {
        if ((offset & (firmware_update::kFlashPageSize - 1)) != 0 ||
            offset > bytes_.size() - firmware_update::kFlashPageSize) {
            return StorageResult::Error;
        }
        if (interrupt_here()) {
            program_bytes(offset, data, firmware_update::kFlashPageSize / 2);
            return StorageResult::Interrupted;
        }
        if (!program_bytes(offset, data, firmware_update::kFlashPageSize)) {
            return StorageResult::Error;
        }
        return interrupt_here() ? StorageResult::Interrupted
                                : StorageResult::Ok;
    }

    StorageResult checkpoint(UpdateCheckpoint) override
    {
        return interrupt_here() ? StorageResult::Interrupted
                                : StorageResult::Ok;
    }

    void load(uint32_t offset, const std::vector<uint8_t>& data)
    {
        std::copy(data.begin(), data.end(), bytes_.begin() + offset);
    }

    void damage(uint32_t offset) { bytes_[offset] ^= 0x80; }

    void fail_once_at(size_t event)
    {
        event_count_ = 0;
        fail_event_ = event;
    }

    void disable_failure()
    {
        event_count_ = 0;
        fail_event_ = 0;
    }

    size_t event_count() const { return event_count_; }
    const std::vector<uint8_t>& bytes() const { return bytes_; }

    bool contains(uint32_t offset, const std::vector<uint8_t>& data) const
    {
        return std::equal(data.begin(), data.end(), bytes_.begin() + offset);
    }

  private:
    bool interrupt_here()
    {
        ++event_count_;
        if (fail_event_ != 0 && event_count_ == fail_event_) {
            fail_event_ = 0;
            return true;
        }
        return false;
    }

    bool program_bytes(uint32_t offset, const uint8_t* data, size_t length)
    {
        for (size_t i = 0; i < length; ++i) {
            if ((bytes_[offset + i] & data[i]) != data[i]) {
                return false;
            }
        }
        for (size_t i = 0; i < length; ++i) {
            bytes_[offset + i] &= data[i];
        }
        return true;
    }

    std::vector<uint8_t> bytes_;
    size_t event_count_ = 0;
    size_t fail_event_ = 0;
};

bool state_is(SimulatedFlash& flash, BoardRevision board, UpdateState state)
{
    const auto journal = firmware_update::read_update_journal(flash, board);
    return journal.valid &&
           journal.record.state == static_cast<uint8_t>(state);
}

bool result_is(SimulatedFlash& flash, BoardRevision board,
               UpdateResult result)
{
    const auto journal = firmware_update::read_update_journal(flash, board);
    return journal.valid &&
           journal.record.result == static_cast<uint8_t>(result);
}

BootDecision resume_after_interruption(SimulatedFlash& flash,
                                       BoardRevision board)
{
    flash.disable_failure();
    for (unsigned attempt = 0; attempt < 4; ++attempt) {
        const BootDecision result =
            firmware_update::process_firmware_boot(flash, board);
        if (result != BootDecision::Interrupted) {
            return result;
        }
    }
    return BootDecision::FlashError;
}

bool test_install_and_confirmation(const std::vector<uint8_t>& old_image,
                                   const std::vector<uint8_t>& candidate,
                                   BoardRevision board)
{
    SimulatedFlash ready_to_mark;
    ready_to_mark.load(firmware_update::kActiveOffset, old_image);
    ready_to_mark.load(firmware_update::kStagingOffset, candidate);

    SimulatedFlash mark_baseline(ready_to_mark.bytes());
    if (!expect(firmware_update::mark_update_pending(mark_baseline, board) ==
                    StorageResult::Ok,
                "create pending journal") ||
        !expect(state_is(mark_baseline, board, UpdateState::Pending),
                "pending journal selected")) {
        return false;
    }
    const size_t mark_events = mark_baseline.event_count();
    for (size_t event = 1; event <= mark_events; ++event) {
        SimulatedFlash interrupted(ready_to_mark.bytes());
        interrupted.fail_once_at(event);
        if (!expect(firmware_update::mark_update_pending(interrupted, board) ==
                        StorageResult::Interrupted,
                    "pending commit fault injection interrupts")) {
            return false;
        }
        interrupted.disable_failure();
        if (!expect(firmware_update::mark_update_pending(interrupted, board) ==
                        StorageResult::Ok,
                    "pending commit is safely retryable") ||
            !expect(state_is(interrupted, board, UpdateState::Pending),
                    "retried pending commit is selected")) {
            return false;
        }
    }

    const std::vector<uint8_t> pending_flash = mark_baseline.bytes();
    SimulatedFlash normal(pending_flash);
    if (!expect(firmware_update::process_firmware_boot(normal, board) ==
                    BootDecision::StartActive,
                "normal install reaches candidate") ||
        !expect(normal.contains(firmware_update::kActiveOffset, candidate),
                "candidate copied to active") ||
        !expect(normal.contains(firmware_update::kRollbackOffset, old_image),
                "old image copied to rollback") ||
        !expect(state_is(normal, board, UpdateState::Trial),
                "normal install enters trial")) {
        return false;
    }
    const size_t install_events = normal.event_count();

    SimulatedFlash confirmation_baseline(normal.bytes());
    if (!expect(firmware_update::confirm_running_firmware(
                    confirmation_baseline, board) ==
                    StorageResult::Ok,
                "candidate confirmation succeeds") ||
        !expect(state_is(confirmation_baseline, board,
                         UpdateState::Confirmed),
                "candidate becomes confirmed") ||
        !expect(result_is(confirmation_baseline, board,
                          UpdateResult::Installed),
                "successful trial records installed result")) {
        return false;
    }
    const size_t confirmation_events = confirmation_baseline.event_count();
    for (size_t event = 1; event <= confirmation_events; ++event) {
        SimulatedFlash interrupted(normal.bytes());
        interrupted.fail_once_at(event);
        if (!expect(firmware_update::confirm_running_firmware(interrupted,
                                                               board) ==
                        StorageResult::Interrupted,
                    "confirmation fault injection interrupts")) {
            return false;
        }
        interrupted.disable_failure();
        if (!expect(firmware_update::confirm_running_firmware(interrupted,
                                                               board) ==
                        StorageResult::Ok,
                    "confirmation is safely retryable") ||
            !expect(state_is(interrupted, board, UpdateState::Confirmed),
                    "retried confirmation is selected")) {
            return false;
        }
    }

    SimulatedFlash unconfirmed(normal.bytes());
    if (!expect(firmware_update::process_firmware_boot(unconfirmed, board) ==
                    BootDecision::StartActive,
                "unconfirmed reset completes rollback") ||
        !expect(unconfirmed.contains(firmware_update::kActiveOffset,
                                     old_image),
                "unconfirmed candidate rolls back") ||
        !expect(state_is(unconfirmed, board, UpdateState::Confirmed),
                "rollback is confirmed") ||
        !expect(result_is(unconfirmed, board, UpdateResult::RolledBack),
                "rollback result is durable")) {
        return false;
    }
    const size_t rollback_events = unconfirmed.event_count();

    for (size_t event = 1; event <= install_events; ++event) {
        SimulatedFlash interrupted(pending_flash);
        interrupted.fail_once_at(event);
        if (!expect(firmware_update::process_firmware_boot(interrupted, board) ==
                        BootDecision::Interrupted,
                    "install fault injection interrupts")) {
            return false;
        }
        if (!expect(resume_after_interruption(interrupted, board) ==
                        BootDecision::StartActive,
                    "install resumes after injected reset")) {
            return false;
        }
        const bool old_active =
            interrupted.contains(firmware_update::kActiveOffset, old_image);
        const bool candidate_active = interrupted.contains(
            firmware_update::kActiveOffset, candidate);
        if (!expect(old_active || candidate_active,
                    "install reset leaves a complete old or new image")) {
            return false;
        }
        if (candidate_active) {
            if (!expect(state_is(interrupted, board, UpdateState::Trial),
                        "new image remains a trial") ||
                !expect(firmware_update::confirm_running_firmware(interrupted,
                                                                   board) ==
                            StorageResult::Ok,
                        "resumed trial confirms")) {
                return false;
            }
        } else if (!expect(state_is(interrupted, board,
                                    UpdateState::Confirmed),
                           "old image is confirmed after recovery")) {
            return false;
        }
    }

    const std::vector<uint8_t> trial_flash = normal.bytes();
    for (size_t event = 1; event <= rollback_events; ++event) {
        SimulatedFlash interrupted(trial_flash);
        interrupted.fail_once_at(event);
        if (!expect(firmware_update::process_firmware_boot(interrupted, board) ==
                        BootDecision::Interrupted,
                    "rollback fault injection interrupts") ||
            !expect(resume_after_interruption(interrupted, board) ==
                        BootDecision::StartActive,
                    "rollback resumes after injected reset") ||
            !expect(interrupted.contains(firmware_update::kActiveOffset,
                                         old_image),
                    "rollback reset leaves old image active") ||
            !expect(state_is(interrupted, board, UpdateState::Confirmed),
                    "rollback reset leaves old image confirmed")) {
            return false;
        }
    }

    std::printf(
        "%s: tested %zu pending, %zu install, %zu confirmation, and %zu "
        "rollback reset points\n",
        board == BoardRevision::B0C ? "B0C" : "B3B", mark_events,
        install_events, confirmation_events, rollback_events);
    return true;
}

bool test_recovery_paths(const std::vector<uint8_t>& old_image,
                         const std::vector<uint8_t>& candidate,
                         BoardRevision board)
{
    SimulatedFlash active;
    active.load(firmware_update::kActiveOffset, old_image);
    if (!expect(firmware_update::process_firmware_boot(active, board) ==
                    BootDecision::StartActive,
                "valid active image boots without a journal")) {
        return false;
    }

    SimulatedFlash rollback;
    rollback.load(firmware_update::kRollbackOffset, old_image);
    if (!expect(firmware_update::process_firmware_boot(rollback, board) ==
                    BootDecision::StartActive,
                "rollback recovers a missing active image") ||
        !expect(rollback.contains(firmware_update::kActiveOffset, old_image),
                "rollback recovery copies complete image")) {
        return false;
    }

    SimulatedFlash staging;
    staging.load(firmware_update::kStagingOffset, candidate);
    if (!expect(firmware_update::process_firmware_boot(staging, board) ==
                    BootDecision::StartActive,
                "staging is the final no-journal recovery source") ||
        !expect(staging.contains(firmware_update::kActiveOffset, candidate),
                "staging recovery copies complete image")) {
        return false;
    }

    SimulatedFlash empty;
    return expect(firmware_update::process_firmware_boot(empty, board) ==
                      BootDecision::EnterUsbRecovery,
                  "no valid images enters USB recovery");
}

bool test_journal_corruption(const std::vector<uint8_t>& old_image,
                             const std::vector<uint8_t>& candidate,
                             BoardRevision board)
{
    SimulatedFlash pending;
    pending.load(firmware_update::kActiveOffset, old_image);
    pending.load(firmware_update::kStagingOffset, candidate);
    if (!expect(firmware_update::mark_update_pending(pending, board) ==
                    StorageResult::Ok,
                "prepare corruption test") ||
        !expect(firmware_update::process_firmware_boot(pending, board) ==
                    BootDecision::StartActive,
                "prepare trial for corruption test")) {
        return false;
    }

    auto newest = firmware_update::read_update_journal(pending, board);
    if (!expect(newest.valid &&
                    newest.record.state ==
                        static_cast<uint8_t>(UpdateState::Trial),
                "trial journal exists before corruption")) {
        return false;
    }
    pending.damage(newest.flash_offset);
    if (!expect(firmware_update::process_firmware_boot(pending, board) ==
                    BootDecision::StartActive,
                "older backup-ready journal survives newest corruption") ||
        !expect(pending.contains(firmware_update::kActiveOffset, candidate),
                "candidate is reinstalled from older journal state") ||
        !expect(state_is(pending, board, UpdateState::Trial),
                "candidate re-enters trial after journal recovery")) {
        return false;
    }

    if (!expect(firmware_update::confirm_running_firmware(pending, board) ==
                    StorageResult::Ok,
                "confirm recovered trial")) {
        return false;
    }
    newest = firmware_update::read_update_journal(pending, board);
    pending.damage(newest.flash_offset);
    if (!expect(firmware_update::process_firmware_boot(pending, board) ==
                    BootDecision::StartActive,
                "older trial journal survives confirmed-record corruption") ||
        !expect(pending.contains(firmware_update::kActiveOffset, old_image),
                "older trial state safely rolls back") ||
        !expect(state_is(pending, board, UpdateState::Confirmed),
                "journal corruption rollback becomes confirmed")) {
        return false;
    }

    SimulatedFlash bad_staging;
    bad_staging.load(firmware_update::kActiveOffset, old_image);
    bad_staging.load(firmware_update::kStagingOffset, candidate);
    if (!expect(firmware_update::mark_update_pending(bad_staging, board) ==
                    StorageResult::Ok,
                "prepare invalid staging test")) {
        return false;
    }
    bad_staging.damage(firmware_update::kStagingOffset + candidate.size() - 1);
    return expect(firmware_update::process_firmware_boot(bad_staging, board) ==
                      BootDecision::StartActive,
                  "invalid pending staging preserves active") &&
           expect(bad_staging.contains(firmware_update::kActiveOffset,
                                       old_image),
                  "invalid pending staging does not replace active") &&
           expect(state_is(bad_staging, board, UpdateState::Confirmed),
                  "invalid pending update is cleared safely");
}

}  // namespace

int main(int argc, char** argv)
{
    if (argc != 4) {
        std::fprintf(stderr,
                     "usage: %s <old.k2fw> <candidate.k2fw> <B0C|B3B>\n",
                     argv[0]);
        return 2;
    }
    const std::vector<uint8_t> old_image = read_file(argv[1]);
    const std::vector<uint8_t> candidate = read_file(argv[2]);
    if (!expect(!old_image.empty() && !candidate.empty(), "read test images")) {
        return 1;
    }
    const std::string board_name = argv[3];
    const BoardRevision board = board_name == "B0C" ? BoardRevision::B0C
                                                     : BoardRevision::B3B;
    if (board_name != "B0C" && board_name != "B3B") {
        return 2;
    }
    return test_install_and_confirmation(old_image, candidate, board) &&
                   test_recovery_paths(old_image, candidate, board) &&
                   test_journal_corruption(old_image, candidate, board)
               ? 0
               : 1;
}
