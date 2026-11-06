#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <dispatch/dispatch.h>
#include "core/config/engine.h"
#include "core/object/class_db.h"
#include "visit_reminder_policy.h"
#include <memory>
#include <mutex>

static NSString *const VISIT_ID = @"inushima.return_visit";
struct PermissionResult {
 std::mutex mutex;
 int generation = 0;
 bool ready = false;
 bool granted = false;
 bool error = false;
};

@interface InushimaVisitReminder : NSObject {
 VisitReminderPolicy _policy;
 NSString *_dogName;
 BOOL _stopped;
}
- (void)configure:(BOOL)enabled name:(NSString *)name;
- (void)synchronize;
- (void)becameActive:(NSNotification *)notification;
- (void)enteredBackground:(NSNotification *)notification;
- (void)shutdown;
@end

@implementation InushimaVisitReminder
- (instancetype)init {
 self = [super init];
 if (self) {
  _dogName = @"Mochi";
  _stopped = NO;
  NSNotificationCenter *events = [NSNotificationCenter defaultCenter];
  [events addObserver:self selector:@selector(becameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
  [events addObserver:self selector:@selector(enteredBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
 }
 return self;
}
- (void)clearOwnedNotifications {
 UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
 [center removePendingNotificationRequestsWithIdentifiers:@[VISIT_ID]];
 [center removeDeliveredNotificationsWithIdentifiers:@[VISIT_ID]];
}
- (void)configure:(BOOL)enabled name:(NSString *)name {
 if (_stopped) return;
 _policy.configure(enabled);
 NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
 _dogName = trimmed.length ? trimmed : @"Mochi";
 if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
  _policy.foreground();
 } else if (!_policy.away) {
  _policy.background([[NSDate date] timeIntervalSince1970]);
 }
 [self synchronize];
}
- (void)becameActive:(NSNotification *)notification {
 if (_stopped) return;
 _policy.foreground();
 [self clearOwnedNotifications];
}
- (void)enteredBackground:(NSNotification *)notification {
 if (_stopped || _policy.away) return;
 _policy.background([[NSDate date] timeIntervalSince1970]);
 [self synchronize];
}
- (void)synchronize {
 if (_stopped) return;
 UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
 [center removePendingNotificationRequestsWithIdentifiers:@[VISIT_ID]];
 if (!_policy.enabled || !_policy.away) {
  [center removeDeliveredNotificationsWithIdentifiers:@[VISIT_ID]];
  return;
 }
 if (_policy.remaining([[NSDate date] timeIntervalSince1970]) <= 0) return;
 const std::uint64_t token = _policy.revision;
 [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
  dispatch_async(dispatch_get_main_queue(), ^{
   if (self->_stopped || !self->_policy.current(token)) return;
   UNAuthorizationStatus status = settings.authorizationStatus;
   if (status != UNAuthorizationStatusAuthorized && status != UNAuthorizationStatusProvisional && status != UNAuthorizationStatusEphemeral) return;
   const double delay = self->_policy.remaining([[NSDate date] timeIntervalSince1970]);
   if (delay <= 0) return;
   UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
   content.body = [NSString stringWithFormat:@"%@ is ready for another visit.", self->_dogName];
   // One visual invitation only: no sound, badge, action buttons, or repeats.
   UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:delay repeats:NO];
   UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:VISIT_ID content:content trigger:trigger];
   [center addNotificationRequest:request withCompletionHandler:^(NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
     // A return to the game or opt-out may have raced the asynchronous add.
     if (!self->_stopped && !self->_policy.current(token)) [self synchronize];
    });
   }];
  });
 }];
}
- (void)shutdown {
 _stopped = YES;
 ++_policy.revision;
 [[NSNotificationCenter defaultCenter] removeObserver:self];
 // Keep an already scheduled background reminder when the app terminates.
}
- (void)dealloc {
 [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

class PuppyReminders : public Object {
 GDCLASS(PuppyReminders, Object);
 InushimaVisitReminder *__strong coordinator = nil;
 std::shared_ptr<PermissionResult> result = std::make_shared<PermissionResult>();
protected:
 static void _bind_methods() {
  ClassDB::bind_method(D_METHOD("configure", "enabled", "dog_name"), &PuppyReminders::configure);
  ClassDB::bind_method(D_METHOD("request_permission"), &PuppyReminders::request_permission);
  ClassDB::bind_method(D_METHOD("get_result"), &PuppyReminders::get_result);
 }
public:
 PuppyReminders() { coordinator = [[InushimaVisitReminder alloc] init]; }
 void configure(bool enabled, const String &name) {
  const CharString utf8 = name.utf8();
  NSString *dog = [[NSString alloc] initWithBytes:utf8.get_data() length:utf8.length() encoding:NSUTF8StringEncoding];
  InushimaVisitReminder *target = coordinator;
  dispatch_async(dispatch_get_main_queue(), ^{ [target configure:enabled name:dog]; });
 }
 void request_permission() {
  auto shared = result;
  int generation;
  {
   std::lock_guard<std::mutex> lock(shared->mutex);
   shared->ready = false;
   generation = ++shared->generation;
  }
  auto finish = [shared, generation](bool granted, bool error) {
   std::lock_guard<std::mutex> lock(shared->mutex);
   if (shared->generation != generation) return;
   shared->granted = granted; shared->error = error; shared->ready = true;
  };
  [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError *error) {
   finish(granted, error != nil);
  }];
 }
 Dictionary get_result() {
  std::lock_guard<std::mutex> lock(result->mutex);
  Dictionary value;
  value["ready"] = result->ready;
  if (result->ready) {
   value["granted"] = result->granted;
   value["error"] = result->error;
   result->ready = false;
  }
  return value;
 }
 ~PuppyReminders() {
  { std::lock_guard<std::mutex> lock(result->mutex); ++result->generation; }
  InushimaVisitReminder *target = coordinator;
  dispatch_async(dispatch_get_main_queue(), ^{ [target shutdown]; });
  coordinator = nil;
 }
};

static PuppyReminders *singleton = nullptr;
void init_puppy_reminders() {
 GDREGISTER_CLASS(PuppyReminders);
 singleton = memnew(PuppyReminders);
 Engine::get_singleton()->add_singleton(Engine::Singleton("PuppyReminders", singleton));
}
void deinit_puppy_reminders() {
 Engine::get_singleton()->remove_singleton("PuppyReminders");
 if (singleton) { memdelete(singleton); singleton = nullptr; }
}
