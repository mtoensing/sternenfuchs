#include "ra/account_session.hpp"

#include <cassert>

int main() {
    sternenfuchs::ra::AccountSession account;
    assert(!account.has_username());
    assert(!account.has_password());
    assert(account.password_mask() == "NOT SET");

    account.set_username("FoxPilot");
    account.set_password("secret");
    assert(account.has_username());
    assert(account.has_password());
    assert(account.username() == "FoxPilot");
    assert(account.password_mask() == "********");
    assert(account.password_for_login() == "secret");

    account.clear_password();
    assert(!account.has_password());
    assert(account.password_for_login().empty());
}
