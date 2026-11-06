#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#include "core/config/engine.h"
#include "core/object/class_db.h"

// Compiled into the containing app by configure_project.rb.
extern "C" void inushima_reload_widget(void);

class PuppyWidgets : public Object {
 GDCLASS(PuppyWidgets, Object);
 NSURL *__strong container = nil;
 double last_reload = 0;
protected:
 static void _bind_methods() {
  ClassDB::bind_method(D_METHOD("is_available"), &PuppyWidgets::is_available);
  ClassDB::bind_method(D_METHOD("publish_snapshot", "json", "leaving"), &PuppyWidgets::publish_snapshot);
 }
public:
 PuppyWidgets() {
  NSString *group = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"InushimaAppGroup"];
  if (group.length) container = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:group];
 }
 bool is_available() const { return container != nil; }
 bool publish_snapshot(const String &json, bool leaving) {
  if (!container) return false;
  const CharString utf8 = json.utf8();
  if (utf8.length() <= 0 || utf8.length() > 4 * 1024 * 1024) return false;
  NSData *data = [NSData dataWithBytes:utf8.get_data() length:utf8.length()];
  id value = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  if (![value isKindOfClass:[NSDictionary class]] || ![value[@"schemaVersion"] isEqual:@1]) return false;
  NSURL *path = [container URLByAppendingPathComponent:@"dog-widget.json"];
  NSError *error = nil;
  if (![data writeToURL:path options:(NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication) error:&error]) return false;
  // Each save updates the shared file. Coalesce foreground reloads, then request
  // a fresh timeline on departure. WidgetKit controls actual delivery timing.
  const double now = [[NSDate date] timeIntervalSince1970];
  if (leaving || now - last_reload >= 60.0 || last_reload == 0) {
   last_reload = now;
   dispatch_async(dispatch_get_main_queue(), ^{ inushima_reload_widget(); });
  }
  return true;
 }
};

static PuppyWidgets *singleton = nullptr;
void init_puppy_widgets() {
 GDREGISTER_CLASS(PuppyWidgets);
 singleton = memnew(PuppyWidgets);
 Engine::get_singleton()->add_singleton(Engine::Singleton("PuppyWidgets", singleton));
}
void deinit_puppy_widgets() {
 Engine::get_singleton()->remove_singleton("PuppyWidgets");
 if (singleton) { memdelete(singleton); singleton = nullptr; }
}
