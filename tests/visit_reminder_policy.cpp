#include "../native/reminders/visit_reminder_policy.h"
#include <cassert>
#include <iostream>

int main() {
 VisitReminderPolicy reminder;
 reminder.background(1000);
 assert(reminder.remaining(1000) == 0); // Opt-in is required.
 reminder.foreground();
 reminder.configure(true);
 assert(reminder.remaining(1000) == 0); // No reminder while playing.
 reminder.background(2000);
 assert(reminder.remaining(2000) == 86400);
 const auto scheduled = reminder.revision;
 reminder.background(3000); // Duplicate lifecycle callbacks cannot delay it.
 assert(reminder.current(scheduled));
 assert(reminder.remaining(3000) == 85400);
 assert(reminder.remaining(88399) == 1);
 assert(reminder.remaining(88400) == 0);
 assert(reminder.remaining(200000) == 0);
 reminder.configure(true); // A late preference refresh cannot repeat it.
 assert(reminder.remaining(200000) == 0);
 reminder.foreground(); // Visiting cancels the old request.
 assert(!reminder.current(scheduled));
 assert(reminder.remaining(200000) == 0);
 reminder.background(200100);
 assert(reminder.remaining(200100) == 86400); // A new absence gets one wait.
 const auto later = reminder.revision;
 reminder.configure(false);
 assert(!reminder.current(later));
 assert(reminder.remaining(200101) == 0);
 reminder.configure(true);
 assert(reminder.remaining(200102) == 86398);
 reminder.foreground();
 assert(reminder.remaining(200102) == 0);
 std::cout << "Visit reminder policy checks: PASS\n";
}
