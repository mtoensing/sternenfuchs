#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "rc_error.h"
#include "rc_runtime.h"

#define WRAM_SIZE 0x20000U

typedef struct {
  uint32_t id;
  const char* title;
  const char* definition;
} achievement_def_t;

static const achievement_def_t k_starfox_achievements[] = {
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
};

static uint8_t g_wram[WRAM_SIZE];
static uint32_t g_triggered_id;
static unsigned g_trigger_count;

static uint32_t peek_memory(uint32_t address, uint32_t num_bytes, void* ud) {
  const uint8_t* memory = (const uint8_t*)ud;
  uint32_t value = 0;
  uint32_t i;

  if (address >= WRAM_SIZE || num_bytes > 4U || address + num_bytes > WRAM_SIZE)
    return 0;

  for (i = 0; i < num_bytes; ++i)
    value |= ((uint32_t)memory[address + i]) << (i * 8U);

  return value;
}

static void event_handler(const rc_runtime_event_t* event) {
  if (event->type == RC_RUNTIME_EVENT_ACHIEVEMENT_TRIGGERED) {
    g_triggered_id = event->id;
    ++g_trigger_count;
  }
}

static void reset_events(void) {
  g_triggered_id = 0U;
  g_trigger_count = 0U;
}

static void set_u16le(uint32_t address, uint16_t value) {
  assert(address + 1U < WRAM_SIZE);
  g_wram[address] = (uint8_t)(value & 0xffU);
  g_wram[address + 1U] = (uint8_t)(value >> 8U);
}

static void assert_all_definitions_activate(void) {
  rc_runtime_t runtime;
  size_t i;

  rc_runtime_init(&runtime);
  for (i = 0; i < sizeof(k_starfox_achievements) / sizeof(k_starfox_achievements[0]); ++i) {
    const int result = rc_runtime_activate_achievement(
        &runtime,
        k_starfox_achievements[i].id,
        k_starfox_achievements[i].definition,
        NULL,
        0);
    if (result != RC_OK) {
      fprintf(stderr, "activation failed: id=%u title=%s result=%d (%s)\n",
          k_starfox_achievements[i].id,
          k_starfox_achievements[i].title,
          result,
          rc_error_str(result));
      assert(result == RC_OK);
    }
  }
  printf("activated %zu/39 real Star Fox achievement definitions\n",
      sizeof(k_starfox_achievements) / sizeof(k_starfox_achievements[0]));
  rc_runtime_destroy(&runtime);
}

static void assert_simple_trigger(void) {
  rc_runtime_t runtime;
  const uint32_t id = 5158U; /* Powerful Payload: 0xH0015af=5 */

  memset(g_wram, 0, sizeof(g_wram));
  reset_events();
  rc_runtime_init(&runtime);
  assert(rc_runtime_activate_achievement(
      &runtime, id, "0xH0015af=5", NULL, 0) == RC_OK);

  g_wram[0x0015afU] = 4U;
  rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
  assert(g_trigger_count == 0U);

  g_wram[0x0015afU] = 5U;
  rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
  assert(g_trigger_count == 1U);
  assert(g_triggered_id == id);

  printf("triggered real single-value achievement %u via synthetic WRAM\n", id);
  rc_runtime_destroy(&runtime);
}

static void assert_delta_trigger(void) {
  rc_runtime_t runtime;
  const uint32_t id = 851U;
  const char* definition =
      "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=21096";

  memset(g_wram, 0, sizeof(g_wram));
  reset_events();
  rc_runtime_init(&runtime);
  assert(rc_runtime_activate_achievement(&runtime, id, definition, NULL, 0) == RC_OK);

  set_u16le(0x001ff9U, 21096U);
  g_wram[0x0015baU] = 0U;
  rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
  assert(g_trigger_count == 0U);

  g_wram[0x0015baU] = 1U;
  rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
  assert(g_trigger_count == 1U);
  assert(g_triggered_id == id);

  printf("triggered real delta/prior achievement %u across two frames\n", id);
  rc_runtime_destroy(&runtime);
}

static void assert_multi_address_trigger(void) {
  rc_runtime_t runtime;
  const uint32_t id = 880U;
  const char* definition =
      "0xH0016d8=2_0xH0016db=10_0xH00a05a=1_0xH0016da=0";

  memset(g_wram, 0, sizeof(g_wram));
  reset_events();
  rc_runtime_init(&runtime);
  assert(rc_runtime_activate_achievement(&runtime, id, definition, NULL, 0) == RC_OK);

  g_wram[0x0016d8U] = 2U;
  g_wram[0x0016dbU] = 10U;
  g_wram[0x00a05aU] = 1U;
  g_wram[0x0016daU] = 1U;
  rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
  assert(g_trigger_count == 0U);

  g_wram[0x0016daU] = 0U;
  rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
  assert(g_trigger_count == 1U);
  assert(g_triggered_id == id);

  printf("triggered real multi-address achievement %u via synthetic WRAM\n", id);
  rc_runtime_destroy(&runtime);
}

static unsigned run_delta_cadence_sequence(int sample_every_phase) {
  rc_runtime_t runtime;
  const uint32_t id = 851U;
  const char* definition =
      "d0xH0015ba=0_0xH0015ba=1_0x 001ff9=21096";
  const uint8_t phase_values[] = {0U, 1U, 0U};
  unsigned phase;

  memset(g_wram, 0, sizeof(g_wram));
  reset_events();
  rc_runtime_init(&runtime);
  assert(rc_runtime_activate_achievement(&runtime, id, definition, NULL, 0) == RC_OK);
  set_u16le(0x001ff9U, 21096U);

  if (sample_every_phase) {
    for (phase = 0; phase < 3U; ++phase) {
      g_wram[0x0015baU] = phase_values[phase];
      rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
    }
  } else {
    /* Model a 20 Hz observer that only sees the beginning and end of the
       three preserved ~60 Hz cartridge/video phases. The 0->1->0 transient
       exists, but the middle phase is not evaluated. */
    g_wram[0x0015baU] = phase_values[0];
    rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
    g_wram[0x0015baU] = phase_values[2];
    rc_runtime_do_frame(&runtime, event_handler, peek_memory, g_wram, NULL);
  }

  phase = g_trigger_count;
  rc_runtime_destroy(&runtime);
  return phase;
}

static void assert_cadence_risk_is_real(void) {
  const unsigned phase_rate_triggers = run_delta_cadence_sequence(1);
  const unsigned logic_rate_triggers = run_delta_cadence_sequence(0);

  assert(phase_rate_triggers == 1U);
  assert(logic_rate_triggers == 0U);

  puts("cadence proof: a real delta achievement can miss a one-phase transient at 20 Hz");
}

int main(void) {
  assert_all_definitions_activate();
  assert_simple_trigger();
  assert_delta_trigger();
  assert_multi_address_trigger();
  assert_cadence_risk_is_real();
  puts("Star Fox synthetic-WRAM rcheevos proof: PASS");
  return 0;
}
