#pragma once

#include <string>
#include <string_view>
#include <utility>

namespace sternenfuchs::ra {

class AccountSession {
public:
    void set_username(std::string value) { username_ = std::move(value); }
    void set_password(std::string value) { password_ = std::move(value); }
    void clear_password() { password_.clear(); }

    [[nodiscard]] std::string_view username() const noexcept {
        return username_;
    }
    [[nodiscard]] bool has_username() const noexcept {
        return !username_.empty();
    }
    [[nodiscard]] bool has_password() const noexcept {
        return !password_.empty();
    }
    [[nodiscard]] std::string password_mask() const {
        return password_.empty() ? std::string{"NOT SET"}
                                 : std::string{"********"};
    }

    // Password is session-only by design. Persist a server-issued token later,
    // never the raw password.
    [[nodiscard]] std::string_view password_for_login() const noexcept {
        return password_;
    }

private:
    std::string username_;
    std::string password_;
};

} // namespace sternenfuchs::ra
