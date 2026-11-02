class_name IslandWeather
extends RefCounted

const TYPES = ["Sunny","Passing clouds","Light rain"]
static var preview = ""

static func at(date: String, hour: int) -> String:
 var slot = absi((date+str(clampi(hour,0,23)/4)).hash()) % 10
 return "Light rain" if slot < 2 else ("Passing clouds" if slot < 6 else "Sunny")

static func current() -> String:
 if preview in TYPES:
  return preview
 var local = Time.get_datetime_dict_from_system(false)
 return at(Time.get_date_string_from_system(false),int(local.hour))

static func greeting(person: String, fallback: String) -> String:
 if current()=="Light rain":
  return {"Nora":"A cozy day for a puppy playdate!", "Ben":"Fresh scents after the rain. Try a scent trail!", "June":"Come shelter from the shower. Take a look around!", "Leah":"A gentle rainy day. How is your little friend?", "Kai":"A passing shower. We can still enjoy a gentle beach game.", "Owen":"A little rain won't stop our ferry stories.", "Ren":"The rain makes a warm light even more welcoming."}.get(person,fallback)
 if current()=="Passing clouds":
  return {"Kai":"Soft clouds and a sea breeze. What shall we try?", "Ben":"A cool day for a trail or a little training."}.get(person,fallback)
 return fallback
