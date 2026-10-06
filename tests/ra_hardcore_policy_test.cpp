#include "ra/hardcore_policy.hpp"

#include <cassert>

int main() {
    using namespace sternenfuchs::ra;

    HardcorePolicy policy;
    assert(policy.mode() == AchievementMode::disabled);
    assert(!policy.is_hardcore());
    assert(policy.can_load_state());
    assert(policy.can_save_state());
    assert(policy.can_use_cheats());
    assert(policy.can_use_scripted_input());
    assert(policy.can_use_direct_stage_entry());

    assert(policy.requires_full_reset_for(AchievementMode::hardcore));
    assert(policy.enter(AchievementMode::casual, SessionOrigin::clean_boot));
    assert(policy.mode() == AchievementMode::casual);
    assert(policy.requires_full_reset_for(AchievementMode::hardcore));

    assert(!policy.enter(AchievementMode::hardcore, SessionOrigin::resumed_state));
    assert(policy.mode() == AchievementMode::casual);

    assert(!policy.enter(AchievementMode::hardcore, SessionOrigin::diagnostic));
    assert(policy.mode() == AchievementMode::casual);

    assert(policy.enter(AchievementMode::hardcore, SessionOrigin::clean_boot));
    assert(policy.is_hardcore());
    assert(!policy.requires_full_reset_for(AchievementMode::hardcore));
    assert(!policy.can_load_state());
    assert(!policy.can_save_state());
    assert(!policy.can_use_cheats());
    assert(!policy.can_use_scripted_input());
    assert(!policy.can_use_direct_stage_entry());
    assert(policy.can_change_playback(PlaybackChange::normal));
    assert(!policy.can_change_playback(PlaybackChange::fast_forward));
    assert(!policy.can_change_playback(PlaybackChange::slowdown));
    assert(!policy.can_change_playback(PlaybackChange::frame_advance));
    assert(!policy.can_change_playback(PlaybackChange::test_super_speed));

    policy.force_casual();
    assert(policy.mode() == AchievementMode::casual);
    assert(policy.can_load_state());
    assert(policy.can_use_cheats());
    assert(policy.can_change_playback(PlaybackChange::fast_forward));
}
