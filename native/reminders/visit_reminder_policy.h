#pragma once
#include <cstdint>

struct VisitReminderPolicy {
 static constexpr double WAIT_SECONDS = 24.0 * 60.0 * 60.0;
 bool enabled = false;
 bool away = false;
 double departed_at = 0;
 std::uint64_t revision = 0;

 void configure(bool value) { enabled = value; ++revision; }
 void foreground() { away = false; ++revision; }
 void background(double now) {
  if (away) return;
  away = true;
  departed_at = now;
  ++revision;
 }
 double remaining(double now) const {
  if (!enabled || !away) return 0;
  const double delay = WAIT_SECONDS - (now - departed_at);
  // A delivered reminder is never repeated during the same absence.
  return delay > 0 && delay <= WAIT_SECONDS ? delay : 0;
 }
 bool current(std::uint64_t token) const { return token == revision; }
};
