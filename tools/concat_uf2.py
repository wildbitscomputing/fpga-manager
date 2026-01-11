import sys


def main() -> int:
    if len(sys.argv) < 3:
        sys.stderr.write("usage: concat_uf2.py <out.uf2> <in1.uf2> [in2.uf2 ...]\n")
        return 1

    out_path = sys.argv[1]
    in_paths = sys.argv[2:]

    with open(out_path, "wb") as fout:
        for path in in_paths:
            with open(path, "rb") as fin:
                while True:
                    chunk = fin.read(1024 * 1024)
                    if not chunk:
                        break
                    fout.write(chunk)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
