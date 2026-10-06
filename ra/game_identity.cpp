#include "ra/game_identity.hpp"

extern "C" {
#include "rc_consoles.h"
#include "rc_hash.h"
}

namespace sternenfuchs::ra {

std::optional<std::string>
hash_snes_file(const std::filesystem::path& path) {
    rc_hash_iterator_t iterator{};
    const auto utf8 = path.string();
    rc_hash_initialize_iterator(&iterator, utf8.c_str(), nullptr, 0U);

    char hash[33]{};
    const auto ok = rc_hash_generate(
        hash, RC_CONSOLE_SUPER_NINTENDO, &iterator);
    rc_hash_destroy_iterator(&iterator);

    if (!ok) return std::nullopt;
    return std::string{hash};
}

} // namespace sternenfuchs::ra
