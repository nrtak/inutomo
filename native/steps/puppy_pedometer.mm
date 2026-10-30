#import <CoreMotion/CoreMotion.h>
#import <Foundation/Foundation.h>
#include "core/config/engine.h"
#include "core/object/class_db.h"
#include <memory>
#include <mutex>
#include <string>

struct StepResult {
 std::mutex mutex;
 bool ready = false;
 int generation = 0;
 int64_t steps = 0;
 std::string day;
 std::string error;
};
class PuppyPedometer : public Object {
 GDCLASS(PuppyPedometer, Object);
 CMPedometer *__strong pedometer = nil;
 std::shared_ptr<StepResult> result = std::make_shared<StepResult>();
protected:
 static void _bind_methods() {
  ClassDB::bind_method(D_METHOD("is_available"), &PuppyPedometer::is_available);
  ClassDB::bind_method(D_METHOD("query_today"), &PuppyPedometer::query_today);
  ClassDB::bind_method(D_METHOD("get_result"), &PuppyPedometer::get_result);
 }
public:
 bool is_available() const { return [CMPedometer isStepCountingAvailable]; }
 void query_today() {
  auto shared = result;
  int generation;
  { std::lock_guard<std::mutex> lock(shared->mutex); shared->ready = false; generation = ++shared->generation; }
  if (!is_available()) {
   std::lock_guard<std::mutex> lock(shared->mutex);
   shared->error = "unavailable"; shared->ready = true; return;
  }
  if (!pedometer) pedometer = [[CMPedometer alloc] init];
  NSDate *now = [NSDate date];
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  calendar.timeZone = [NSTimeZone localTimeZone];
  NSDate *start = [calendar startOfDayForDate:now];
  NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now];
  NSString *date = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)components.year, (long)components.month, (long)components.day];
  std::string day([date UTF8String]);
  [pedometer queryPedometerDataFromDate:start toDate:now withHandler:^(CMPedometerData *data, NSError *error) {
   std::lock_guard<std::mutex> lock(shared->mutex);
   if (shared->generation != generation) return;
   shared->day = day;
   shared->steps = data ? [data.numberOfSteps longLongValue] : 0;
   shared->error = error || !data ? "unavailable_or_denied" : "";
   shared->ready = true;
  }];
 }
 Dictionary get_result() {
  std::lock_guard<std::mutex> lock(result->mutex);
  Dictionary value;
  value["ready"] = result->ready;
  if (result->ready) {
   value["day"] = String::utf8(result->day.c_str());
   value["steps"] = result->steps;
   value["error"] = String::utf8(result->error.c_str());
   result->ready = false;
  }
  return value;
 }
 ~PuppyPedometer() {
  std::lock_guard<std::mutex> lock(result->mutex);
  ++result->generation;
  [pedometer stopPedometerUpdates];
  pedometer = nil;
 }
};
static PuppyPedometer *singleton = nullptr;
void init_puppy_pedometer() {
 GDREGISTER_CLASS(PuppyPedometer);
 singleton = memnew(PuppyPedometer);
 Engine::get_singleton()->add_singleton(Engine::Singleton("PuppyPedometer", singleton));
}
void deinit_puppy_pedometer() {
 Engine::get_singleton()->remove_singleton("PuppyPedometer");
 if (singleton) { memdelete(singleton); singleton = nullptr; }
}
