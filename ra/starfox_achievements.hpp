#pragma once

#include <array>
#include <cstdint>
#include <string_view>

namespace sternenfuchs::ra {

struct AchievementDefinition {
    std::uint32_t id;
    std::string_view title;
    std::string_view definition;
};

inline constexpr std::array<AchievementDefinition, 39> kStarFoxAchievements{{
    {5138U, "The Peppy Special", "0xH001503>10_R:0x00157a=48383_R:0xH001503=85_0xH00033a=32_0xH00a05a=1"},
    {851U, "Crushing the Crusher I", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=21096"},
    {849U, "Shoot the Core!", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=21187"},
    {850U, "Our Last Dance", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=21894"},
    {852U, "Phantron of the Space Opera", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=22018"},
    {853U, "Cosmic Climax", "N:0x 001ff9!=22143_R:0x 001ff9!=22018_I:0x 0016f9_N:0xH00002a=62.1._N:d0xS0014d8=0_0xS0014d8=1_O:0xH000396=0_R:0xH000396>=128"},
    {854U, "Star Fox's Beginner Victory", "O:0x 001ff9=22143_0x 001ff9=22018_0xR0014d8=1_0xS0014d8=1_0xT0014d8>d0xT0014d8"},
    {855U, "Crushing the Crusher II", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=24396"},
    {856U, "Hangar Out to Dry", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=24487"},
    {857U, "Lean, Mean, Lernaean Machine", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=24618"},
    {859U, "More than Scrap Metal", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=24709"},
    {858U, "Riding a Thin Line", "N:0x 001ff9!=24821_R:0x 001ff9!=24709_I:0x 0016f9_N:0xH00002a=64.1._N:d0xS0014d8=0_0xS0014d8=1_O:0xH000396=0_R:0xH000396>=128"},
    {860U, "Star Fox's Intermediate Victory", "O:0x 001ff9=24821_0x 001ff9=24709_0xR0014d8=1_0xS0014d8=1_0xT0014d8>d0xT0014d8"},
    {872U, "Cutting-Edge Technology", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=26102"},
    {873U, "Protect Your Necks", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=26193"},
    {874U, "Particle Acceleration", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=26328"},
    {875U, "Now In Rotation", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=26652"},
    {876U, "Taking Command", "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=26809"},
    {877U, "The Final Goal", "O:0x 001ff9=26921_0x 001ff9=26809_0xH001fc4!=0_d0xS0014d8=1_d0xR0014d8=0_0xR0014d8=1_0xH000396>0"},
    {878U, "Star Fox's Expert Victory", "O:0x 001ff9=26921_0x 001ff9=26809_0xR0014d8=1_0xS0014d8=1_0xT0014d8>d0xT0014d8"},
    {880U, "Welcome to Warp Zone!", "0xH0016d8=2_0xH0016db=10_0xH00a05a=1_0xH0016da=0"},
    {892U, "1993: A Strange Odyssey", "0xH0016d8=2_0xH0016db=14_0xH00a05a=1_0xH0016da=2"},
    {5160U, "Look Pepper, No Wings!", "0xH00033a=228"},
    {2362U, "Hare-Raising Endurance", "0xH00175f=100_0xH0016d8=0_0xH0016db=0_0xH00a05a=0_0xH0016da=0"},
    {5158U, "Powerful Payload", "0xH0015af=5"},
    {5164U, "Twin Powers Activate!", "0xH0000fd=1_0xM0014d9>d0xM0014d9"},
    {5165U, "BioShock", "0xH0000fd=1_0xQ0014da>d0xQ0014da"},
    {5167U, "Jackpot!", "0x 00157a=15615_0xH0016bd=2_0xH0016be=2_d0xH0016bd=1_d0xH0016be=1_0xH0016d8=2_0xH0016db=14_0xH00a05a=1_0xH0016da=2"},
    {5153U, "It's Not Easy Being Green", "0x00189c=23299"},
    {5154U, "Animal Crossing", "0x00189c=18177"},
    {5155U, "Falcon Punch!", "0x00189c=20738"},
    {5162U, "Caught Slippin'", "0x00189c=4355"},
    {5156U, "Hey, He Was Mine!", "0x00189c=13313"},
    {5157U, "Mind Your Own Business, Fox!", "0x00189c=43778"},
    {5159U, "Slipster", "0x00189c=2563"},
    {5179U, "Captain Peppy O'Hare", "0x00189c=62977"},
    {5163U, "Roger, Falco", "0xH0016db<16S0x00189c=58882S0x00189c=64770"},
    {5161U, "Corneria Champion", "0xH001fbf=100_d0xH0015ba=0_0xH0015ba=1.1._O:0x 001ff9=20584_O:0x 001ff9=23910_0x 001ff9=25551_N:0x 001ff9!=20584_N:0x 001ff9!=23910_R:0x 001ff9!=25551"},
    {5166U, "Liberator of Lylat", "0xH001fbf>=95_0xH001fc0>=95_0xH001fc1>=95_0xH001fc2>=95_0xH001fc3>=95_0xH001fc4>=95_0xH001fc0!=101Sd0xH001fc4=0_0xH001fc5=0Sd0xH001fc5=0_0xH001fc5>=95"}
}};

} // namespace sternenfuchs::ra
