#include "ra/game_identity.hpp"

#include <filesystem>
#include <iostream>

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "usage: ra-hash-rom ROM.sfc|ROM.smc\n";
        return 2;
    }

    const std::filesystem::path path{argv[1]};
    const auto hash = sternenfuchs::ra::hash_snes_file(path);
    if (!hash) {
        std::cerr << "RA_HASH_ERROR path=" << path.string() << "\n";
        return 1;
    }

    const auto size = std::filesystem::file_size(path);
    const bool copier_header = size > 512U && (size % 0x8000U) == 512U;

    std::cout << "RA_HASH=" << *hash << "\n";
    std::cout << "FILE_SIZE=" << size << "\n";
    std::cout << "COPIER_HEADER=" << (copier_header ? "yes" : "no") << "\n";
    return 0;
}
