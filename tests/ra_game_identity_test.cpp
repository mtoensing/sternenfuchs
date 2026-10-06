#include "ra/game_identity.hpp"

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

namespace {

void write_file(const std::filesystem::path& path,
    const std::vector<std::uint8_t>& bytes) {
    std::ofstream out(path, std::ios::binary);
    assert(out);
    out.write(reinterpret_cast<const char*>(bytes.data()),
        static_cast<std::streamsize>(bytes.size()));
    assert(out.good());
}

bool valid_hash(const std::optional<std::string>& hash) {
    if (!hash || hash->size() != 32U) return false;
    for (const char c : *hash) {
        const bool hex = (c >= '0' && c <= '9')
            || (c >= 'a' && c <= 'f')
            || (c >= 'A' && c <= 'F');
        if (!hex) return false;
    }
    return true;
}

} // namespace

int main() {
    const auto dir = std::filesystem::temp_directory_path()
        / "sternenfuchs-ra-hash-test";
    std::filesystem::remove_all(dir);
    std::filesystem::create_directories(dir);

    std::vector<std::uint8_t> payload(512U * 1024U);
    for (std::size_t i = 0; i < payload.size(); ++i)
        payload[i] = static_cast<std::uint8_t>((i * 37U + 11U) & 0xffU);

    const auto sfc = dir / "synthetic.sfc";
    write_file(sfc, payload);

    std::vector<std::uint8_t> headered(512U + payload.size(), 0x5aU);
    std::copy(payload.begin(), payload.end(), headered.begin() + 512U);
    const auto smc = dir / "synthetic.smc";
    write_file(smc, headered);

    const auto sfc_hash_1 = sternenfuchs::ra::hash_snes_file(sfc);
    const auto sfc_hash_2 = sternenfuchs::ra::hash_snes_file(sfc);
    const auto smc_hash = sternenfuchs::ra::hash_snes_file(smc);

    assert(valid_hash(sfc_hash_1));
    assert(valid_hash(sfc_hash_2));
    assert(valid_hash(smc_hash));
    assert(*sfc_hash_1 == *sfc_hash_2);
    // rcheevos intentionally normalizes the common 512-byte SNES copier
    // header, so equivalent headered/unheadered media resolve to one identity.
    assert(*sfc_hash_1 == *smc_hash);

    const auto missing = sternenfuchs::ra::hash_snes_file(
        dir / "missing.sfc");
    assert(!missing);

    std::filesystem::remove_all(dir);
}
