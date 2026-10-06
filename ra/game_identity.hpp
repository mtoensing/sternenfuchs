#pragma once

#include <filesystem>
#include <optional>
#include <string>

namespace sternenfuchs::ra {

[[nodiscard]] std::optional<std::string>
hash_snes_file(const std::filesystem::path& path);

} // namespace sternenfuchs::ra
