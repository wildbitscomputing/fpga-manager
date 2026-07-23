#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lz4.h"

#define BLOCK_SIZE 32768

static int write_u32(FILE* f, uint32_t v)
{
    uint8_t b[4];
    b[0] = (uint8_t)(v & 0xff);
    b[1] = (uint8_t)((v >> 8) & 0xff);
    b[2] = (uint8_t)((v >> 16) & 0xff);
    b[3] = (uint8_t)((v >> 24) & 0xff);
    return fwrite(b, 1, 4, f) == 4 ? 0 : -1;
}

static int read_block(FILE* f, uint8_t* buf, size_t* out_len)
{
    size_t n = fread(buf, 1, BLOCK_SIZE, f);
    *out_len = n;
    return ferror(f) ? -1 : 0;
}

int main(int argc, char** argv)
{
    if (argc != 3) {
        fprintf(stderr, "usage: %s <input.bin> <output.lz4>\n", argv[0]);
        return 1;
    }

    const char* in_path = argv[1];
    const char* out_path = argv[2];

    FILE* fin = fopen(in_path, "rb");
    if (!fin) {
        perror("open input");
        return 1;
    }

    FILE* fout = fopen(out_path, "wb");
    if (!fout) {
        perror("open output");
        fclose(fin);
        return 1;
    }

    if (fseek(fin, 0, SEEK_END) != 0) {
        perror("seek input");
        fclose(fin);
        fclose(fout);
        return 1;
    }
    long total_size = ftell(fin);
    if (total_size < 0) {
        perror("tell input");
        fclose(fin);
        fclose(fout);
        return 1;
    }
    if (fseek(fin, 0, SEEK_SET) != 0) {
        perror("seek input");
        fclose(fin);
        fclose(fout);
        return 1;
    }

    if (write_u32(fout, (uint32_t)total_size) != 0) {
        fprintf(stderr, "write output header failed\n");
        fclose(fin);
        fclose(fout);
        return 1;
    }

    uint8_t* in_buf = (uint8_t*)malloc(BLOCK_SIZE);
    uint8_t* out_buf = (uint8_t*)malloc(LZ4_COMPRESSBOUND(BLOCK_SIZE));
    if (!in_buf || !out_buf) {
        fprintf(stderr, "alloc failed\n");
        free(in_buf);
        free(out_buf);
        fclose(fin);
        fclose(fout);
        return 1;
    }

    for (;;) {
        size_t in_len = 0;
        if (read_block(fin, in_buf, &in_len) != 0) {
            fprintf(stderr, "read failed\n");
            free(in_buf);
            free(out_buf);
            fclose(fin);
            fclose(fout);
            return 1;
        }
        if (in_len == 0) {
            break;
        }

        int comp_len = LZ4_compress_default((const char*)in_buf, (char*)out_buf,
                                            (int)in_len, LZ4_COMPRESSBOUND(BLOCK_SIZE));
        if (comp_len <= 0) {
            fprintf(stderr, "compress failed\n");
            free(in_buf);
            free(out_buf);
            fclose(fin);
            fclose(fout);
            return 1;
        }

        if (write_u32(fout, (uint32_t)in_len) != 0 ||
            write_u32(fout, (uint32_t)comp_len) != 0) {
            fprintf(stderr, "write block header failed\n");
            free(in_buf);
            free(out_buf);
            fclose(fin);
            fclose(fout);
            return 1;
        }
        if (fwrite(out_buf, 1, (size_t)comp_len, fout) != (size_t)comp_len) {
            fprintf(stderr, "write block failed\n");
            free(in_buf);
            free(out_buf);
            fclose(fin);
            fclose(fout);
            return 1;
        }
    }

    if (write_u32(fout, 0) != 0 || write_u32(fout, 0) != 0) {
        fprintf(stderr, "write end marker failed\n");
        free(in_buf);
        free(out_buf);
        fclose(fin);
        fclose(fout);
        return 1;
    }

    free(in_buf);
    free(out_buf);
    fclose(fin);
    fclose(fout);
    return 0;
}
