#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "firmware_staging.h"
#include "firmware_update_layout.h"

namespace {

using firmware_update::BoardRevision;
using firmware_update::FirmwareReceiveError;
using firmware_update::FirmwareReceiveState;
using firmware_update::FirmwareStorage;
using firmware_update::StorageResult;
using firmware_update::UpdateCheckpoint;
using firmware_update::UpdateState;

bool expect(bool condition, const char* message)
{
    if (!condition) {
        std::fprintf(stderr, "staging test failed: %s\n", message);
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
        for (size_t i = 0; i < firmware_update::kFlashPageSize; ++i) {
            if ((bytes_[offset + i] & data[i]) != data[i]) {
                return StorageResult::Error;
            }
        }
        if (interrupt_here()) {
            for (size_t i = 0; i < firmware_update::kFlashPageSize / 2; ++i) {
                bytes_[offset + i] &= data[i];
            }
            return StorageResult::Interrupted;
        }
        for (size_t i = 0; i < firmware_update::kFlashPageSize; ++i) {
            bytes_[offset + i] &= data[i];
        }
        return interrupt_here() ? StorageResult::Interrupted
                                : StorageResult::Ok;
    }

    StorageResult checkpoint(UpdateCheckpoint) override
    {
        return interrupt_here() ? StorageResult::Interrupted
                                : StorageResult::Ok;
    }

    void load(uint32_t offset, const std::vector<uint8_t>& image)
    {
        std::copy(image.begin(), image.end(), bytes_.begin() + offset);
    }

    void fill(uint32_t offset, size_t length, uint8_t value)
    {
        std::fill_n(bytes_.begin() + offset, length, value);
    }

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

    bool contains(uint32_t offset, const std::vector<uint8_t>& image) const
    {
        return std::equal(image.begin(), image.end(), bytes_.begin() + offset);
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

    std::vector<uint8_t> bytes_;
    size_t event_count_ = 0;
    size_t fail_event_ = 0;
};

bool send_manifest(firmware_update::FirmwareStagingReceiver& receiver,
                   const std::vector<uint8_t>& package)
{
    uint32_t offset = 0;
    while (offset < firmware_update::kManifestSectorSize) {
        const size_t amount = std::min<size_t>(
            232, firmware_update::kManifestSectorSize - offset);
        if (!receiver.write(offset, package.data() + offset, amount)) {
            return false;
        }
        offset += static_cast<uint32_t>(amount);
    }
    return true;
}

bool erase_staging(firmware_update::FirmwareStagingReceiver& receiver)
{
    for (unsigned step = 0; step < 1024; ++step) {
        if (receiver.status().state == FirmwareReceiveState::Payload) {
            return true;
        }
        receiver.service_step();
    }
    return false;
}

bool send_payload(firmware_update::FirmwareStagingReceiver& receiver,
                  const std::vector<uint8_t>& package)
{
    uint32_t offset = firmware_update::kManifestSectorSize;
    while (offset < package.size()) {
        const size_t amount = std::min<size_t>(232, package.size() - offset);
        if (!receiver.write(offset, package.data() + offset, amount)) {
            return false;
        }
        offset += static_cast<uint32_t>(amount);
    }
    return true;
}

bool test_complete_transfer(const std::vector<uint8_t>& old_image,
                            const std::vector<uint8_t>& candidate,
                            BoardRevision board)
{
    SimulatedFlash flash;
    flash.load(firmware_update::kActiveOffset, old_image);
    firmware_update::FirmwareStagingReceiver receiver;
    receiver.initialize(&flash, board);
    if (!expect(receiver.begin(candidate.size()), "begin transfer") ||
        !expect(send_manifest(receiver, candidate), "receive manifest") ||
        !expect(receiver.status().state == FirmwareReceiveState::Erasing,
                "manifest starts erase") ||
        !expect(!receiver.write(firmware_update::kManifestSectorSize,
                                candidate.data() +
                                    firmware_update::kManifestSectorSize,
                                1),
                "payload rejected while erase is busy") ||
        !expect(receiver.status().error == FirmwareReceiveError::Busy,
                "busy status is reported") ||
        !expect(erase_staging(receiver), "incremental erase finishes") ||
        !expect(send_payload(receiver, candidate), "receive payload") ||
        !expect(receiver.finish(), "finish transfer") ||
        !expect(receiver.ready_to_apply(), "candidate ready to apply") ||
        !expect(firmware_update::validate_firmware_image(
                    flash.read(firmware_update::kStagingOffset,
                               candidate.size()),
                    board) == firmware_update::ImageValidation::Ok,
                "staged image validates")) {
        return false;
    }
    const auto journal = firmware_update::read_update_journal(flash, board);
    return expect(journal.valid &&
                      journal.record.state ==
                          static_cast<uint8_t>(UpdateState::Pending) &&
                      journal.record.result == static_cast<uint8_t>(
                          firmware_update::UpdateResult::None),
                  "pending journal committed");
}

bool drive_transfer(firmware_update::FirmwareStagingReceiver& receiver,
                    const std::vector<uint8_t>& candidate)
{
    if (!receiver.begin(candidate.size()) ||
        !send_manifest(receiver, candidate)) {
        return false;
    }
    while (receiver.status().state == FirmwareReceiveState::Erasing) {
        receiver.service_step();
    }
    if (receiver.status().state != FirmwareReceiveState::Payload ||
        !send_payload(receiver, candidate)) {
        return false;
    }
    return receiver.finish();
}

bool test_staging_reset_points(const std::vector<uint8_t>& old_image,
                               const std::vector<uint8_t>& candidate,
                               BoardRevision board)
{
    SimulatedFlash baseline;
    baseline.load(firmware_update::kActiveOffset, old_image);
    baseline.fill(firmware_update::kStagingOffset,
                  firmware_update::kApplicationSlotSize, 0x00);
    firmware_update::FirmwareStagingReceiver baseline_receiver;
    baseline_receiver.initialize(&baseline, board);
    if (!expect(drive_transfer(baseline_receiver, candidate),
                "fault baseline transfer succeeds")) {
        return false;
    }
    const size_t events = baseline.event_count();

    for (size_t event = 1; event <= events; ++event) {
        SimulatedFlash flash;
        flash.load(firmware_update::kActiveOffset, old_image);
        flash.fill(firmware_update::kStagingOffset,
                   firmware_update::kApplicationSlotSize, 0x00);
        flash.fail_once_at(event);
        firmware_update::FirmwareStagingReceiver receiver;
        receiver.initialize(&flash, board);
        if (!expect(!drive_transfer(receiver, candidate),
                    "injected staging reset interrupts transfer")) {
            return false;
        }

        flash.disable_failure();
        const auto decision =
            firmware_update::process_firmware_boot(flash, board);
        if (!expect(decision == firmware_update::BootDecision::StartActive,
                    "staging reset leaves a bootable application")) {
            return false;
        }
        const bool old_active =
            flash.contains(firmware_update::kActiveOffset, old_image);
        const bool candidate_active =
            flash.contains(firmware_update::kActiveOffset, candidate);
        if (!expect(old_active || candidate_active,
                    "staging reset leaves old or fully installed candidate")) {
            return false;
        }
        if (candidate_active &&
            !expect(firmware_update::confirm_running_firmware(flash, board) ==
                        StorageResult::Ok,
                    "candidate installed after final commit can confirm")) {
            return false;
        }
    }
    std::printf("%s: tested %zu staging reset points\n",
                board == BoardRevision::B0C ? "B0C" : "B3B", events);
    return true;
}

bool test_rejections(const std::vector<uint8_t>& old_image,
                     const std::vector<uint8_t>& candidate,
                     const std::vector<uint8_t>& older,
                     BoardRevision board)
{
    SimulatedFlash flash;
    flash.load(firmware_update::kActiveOffset, old_image);
    flash.fill(firmware_update::kStagingOffset,
               firmware_update::kFlashSectorSize, 0x5a);
    firmware_update::FirmwareStagingReceiver receiver;
    receiver.initialize(&flash, board);

    auto wrong_board = candidate;
    wrong_board[12] = board == BoardRevision::B0C ? 2 : 1;
    // Recompute neither CRC nor anything else: it must still be rejected
    // before staging is erased.
    if (!expect(receiver.begin(wrong_board.size()), "begin bad manifest") ||
        !expect(!send_manifest(receiver, wrong_board),
                "bad manifest rejected") ||
        !expect(receiver.status().state == FirmwareReceiveState::Failed,
                "bad manifest fails receiver") ||
        !expect(flash.read(firmware_update::kStagingOffset, 1)[0] == 0x5a,
                "bad manifest does not erase staging")) {
        return false;
    }

    receiver.initialize(&flash, board);
    if (!expect(receiver.begin(older.size()), "begin downgrade") ||
        !expect(!send_manifest(receiver, older), "downgrade rejected") ||
        !expect(receiver.status().error == FirmwareReceiveError::Downgrade,
                "downgrade error reported") ||
        !expect(flash.read(firmware_update::kStagingOffset, 1)[0] == 0x5a,
                "downgrade does not erase staging")) {
        return false;
    }

    receiver.initialize(&flash, board);
    if (!expect(receiver.begin(candidate.size()), "restart receiver") ||
        !expect(!receiver.write(1, candidate.data(), 16),
                "out-of-order offset rejected") ||
        !expect(receiver.status().error == FirmwareReceiveError::BadOffset,
                "offset error reported") ||
        !expect(receiver.abort(), "abort incomplete transfer")) {
        return false;
    }

    auto corrupt_payload = candidate;
    corrupt_payload.back() ^= 0x80;
    receiver.initialize(&flash, board);
    if (!expect(receiver.begin(corrupt_payload.size()), "begin corrupt data") ||
        !expect(send_manifest(receiver, corrupt_payload),
                "valid manifest accepted") ||
        !expect(erase_staging(receiver), "erase for corrupt data") ||
        !expect(send_payload(receiver, corrupt_payload),
                "receive corrupt payload") ||
        !expect(!receiver.finish(), "payload hash mismatch rejected") ||
        !expect(receiver.status().error == FirmwareReceiveError::BadHash,
                "hash error reported") ||
        !expect(flash.read(firmware_update::kStagingOffset, 4)[0] == 0xff,
                "manifest remains erased after bad hash") ||
        !expect(firmware_update::process_firmware_boot(flash, board) ==
                    firmware_update::BootDecision::StartActive,
                "incomplete staging does not prevent active boot")) {
        return false;
    }
    return true;
}

}  // namespace

int main(int argc, char** argv)
{
    if (argc != 5) {
        std::fprintf(stderr,
                     "usage: %s <old.k2fw> <candidate.k2fw> <older.k2fw> "
                     "<B0C|B3B>\n",
                     argv[0]);
        return 2;
    }
    const std::string board_name = argv[4];
    if (board_name != "B0C" && board_name != "B3B") {
        return 2;
    }
    const BoardRevision board = board_name == "B0C" ? BoardRevision::B0C
                                                     : BoardRevision::B3B;
    const auto old_image = read_file(argv[1]);
    const auto candidate = read_file(argv[2]);
    const auto older = read_file(argv[3]);
    return test_complete_transfer(old_image, candidate, board) &&
                   test_staging_reset_points(old_image, candidate, board) &&
                   test_rejections(old_image, candidate, older, board)
               ? 0
               : 1;
}
