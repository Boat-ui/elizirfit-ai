**GhanaFit --- Complete Product & Engineering Specification**

**Working title --- rename freely.** This is one document, meant to be
handed to any Claude session (chat or Claude Code) as the single source
of truth to build from. It covers the product, the screens, the data,
and the technical decisions. Nothing here is repeated elsewhere and
nothing is padded --- if a section is short, it\'s because that\'s all
it needs.

**1. What This App Is**

A mobile fitness and nutrition tracker for Ghana. It does four things
well:

1.  **Nutrition tracking** built around Ghanaian food --- search or scan
    what you actually eat, not a Western food list with a few local
    dishes bolted on.

2.  **Barcode/QR scanning** of packaged products sold in Ghana, so
    processed food is as easy to log as home-cooked food.

3.  **Workout logging** --- sets, reps, weight, and personal records, so
    you can see progress over time.

4.  **Activity tracking** --- walking, running, cycling, and other
    cardio, with calories burned.

**Who it\'s for:** anyone in Ghana trying to lose weight, build muscle,
or just keep a real record of what they eat and how they train ---
currently underserved by fitness apps because none of them recognize
local food or products.

**What makes it different:** the food and product databases are built
for Ghana specifically, not adapted from a US database after the fact.

**2. Build Philosophy**

-   **Ship the core loop first.** Nutrition + workout + activity
    logging, working offline, in one country. Everything else is a later
    phase.

-   **Offline-first.** Ghana has real, common gaps in mobile
    connectivity. Every core feature (logging a meal, a workout, an
    activity) must work with no internet and sync automatically once it
    returns.

-   **Be honest about data quality.** Nutrition values that are
    estimated rather than lab-verified get marked as such in the data
    and, eventually, in the UI. Never present a guess as a certainty.

-   **Small, real datasets over huge fake ones.** A working 150-food
    database beats a promised 5,000-food database that never gets built.
    Every dataset below has a realistic starting size and a real path to
    grow it.

**3. Technical Stack**

  -----------------------------------------------------------------------
  **Layer**     **Choice**                    **Why**
  ------------- ----------------------------- ---------------------------
  Mobile app    **Flutter (Dart)**            Single codebase for iOS and
                                              Android, strong offline
                                              story, mature
                                              camera/barcode plugins.

  State         **Riverpod**                  Standard, testable choice
  management                                  for new Flutter apps;
                                              avoids passing state
                                              through widget trees by
                                              hand.

  Local         **SQLite** (via sqflite)      Needed for the
  database                                    offline-first requirement
                                              --- meals, workouts, and
                                              activity must be queryable
                                              with zero network.

  Backend       **Supabase** (hosted          Real relational database,
  (added once   Postgres + Auth + Storage)    built-in auth, and file
  the local app                               storage without
  works)                                      hand-building a custom
                                              backend before there\'s
                                              anything to sync.

  Sync strategy Local SQLite is the source of Simple, no custom
                truth offline. Every          conflict-resolution engine
                write-table has a synced      needed at this scale ---
                flag; a background sync       last-write-wins is fine for
                pushes unsynced rows to       a single-user app.
                Supabase when online.         

  Barcode/QR    mobile_scanner package        Uses on-device ML
  scanning                                    Kit/AVFoundation --- scans
                                              work with no server
                                              round-trip.
  -----------------------------------------------------------------------

Nothing above is provisional --- these are the actual choices to build
against, not options to pick between later.

**4. Feature Scope: MVP vs. Later**

The single most important table in this document. Build v1 exactly as
scoped --- resist adding Phase 2/3 items until v1 is working and in real
use.

  ----------------------------------------------------------------------------------------------
  **Module**      **v1 (MVP)**                      **Phase 2**           **Phase 3**
  --------------- --------------------------------- --------------------- ----------------------
  **Nutrition**   Search & log Ghanaian foods, meal Saved/reusable meal   Budget meal planning
                  types                             combos, AI food-photo tied to market prices
                  (breakfast/lunch/dinner/snack),   recognition with      
                  barcode/QR product scanning,      portion estimation,   
                  daily calorie & macro totals,     grocery-basket        
                  water tracker                     scanner               

  **Workout**     Curated exercise library          Workout               Trainer/coach
                  (\~150--200 exercises), set       programs/templates,   dashboard for managing
                  logging (reps/weight/RPE),        custom workout        multiple clients
                  workout history, personal-record  builder,              
                  tracking per exercise             supersets/dropsets    

  **Activity**    Manual logging of                 GPS-tracked           Wearable integration
                  walk/run/cycle/other with         runs/walks with       (Health Connect, Apple
                  duration, optional distance,      route, pace, splits   Health, Garmin)
                  calorie estimate (MET-based                             
                  formula)                                                

  **Progress**    Weight log with trend chart       Body measurements     Body-fat/muscle-mass
                                                    (waist, chest, arms,  estimation
                                                    etc.), progress       
                                                    photos                

  **Profile &     Age, height, weight, sex,         Equipment available,  Family accounts
  Goals**         activity level, goal              allergies/medical     
                  (lose/gain/maintain), computed    notes                 
                  maintenance calories & macros                           

  **AI            Not in v1                         Text Q&A over the     Recovery scoring,
  Assistant**                                       user\'s own logged    sleep-based
                                                    data (\"how much      recommendations
                                                    protein have I had    
                                                    today?\")             

  **Social**      Not in v1                         Not in v1             Friends, leaderboards,
                                                                          challenges

  **Auth**        Email/password, guest mode        Google/Apple sign-in  Phone/OTP, biometrics
  ----------------------------------------------------------------------------------------------

**Definition of done for v1:** a user can install the app, log a meal
(by search or barcode scan), log a workout, log an activity, and see
today\'s totals --- fully offline, syncing when connectivity returns.

**5. Screen Inventory**

Every screen needed for v1, with purpose and key elements. Loading,
empty, error, and offline states apply to every screen listed and
aren\'t repeated per-screen below.

**Auth & onboarding**

-   Splash → routes to Login or Dashboard based on session.

-   Login --- email/password, guest mode, forgot-password link.

-   Sign Up --- email, password, confirm.

-   Onboarding --- name → age/sex → height/weight → activity level →
    goal → a summary screen showing the computed calorie/macro target
    before entering the app.

**Dashboard**

-   Calorie ring (consumed / remaining / target), macro bars, water
    widget, today\'s workout status, quick actions (Scan Food, Add Meal,
    Start Workout, Log Activity, Weigh In), recent meal card.

**Nutrition**

-   Nutrition Home --- today\'s meals grouped by type, running totals,
    \"Log meal\" action.

-   Food Search --- search bar, recent/favorite foods, results list.

-   Food Detail --- full macro breakdown, serving-size adjuster,
    add-to-meal.

-   Barcode/QR Scan --- camera view, live detection, matched-product
    card, or a clear \"not found, search by name\" fallback.

-   Log Meal --- meal-type selector, quantity stepper, live calorie
    preview.

-   Water Tracker --- daily target, quick-add buttons, history.

**Workout**

-   Workout Home --- session history, \"Start workout\" action.

-   Active Workout --- exercise picker, set logger (reps/weight/RPE),
    running session list, \"Finish.\"

-   Exercise Library --- searchable/filterable by muscle group and
    equipment, exercise detail with instructions.

-   Workout Detail --- full past-session breakdown.

-   Personal Records --- best set per exercise, most recent first.

**Activity**

-   Activity Home --- today\'s logged activities, total calories burned.

-   Log Activity --- type selector, duration, optional distance, live
    calorie estimate.

**Progress**

-   Weight trend chart, \"Weigh in\" action.

**Profile & Settings**

-   Editable personal stats and goal, computed targets.

-   Units (metric/imperial), notifications toggle, dark mode, logout.

**6. Data Model**

CREATE TABLE users (

id TEXT PRIMARY KEY,

name TEXT NOT NULL,

email TEXT UNIQUE NOT NULL,

age INTEGER,

sex TEXT, \-- \'male\' \| \'female\' \| \'other\'

height_cm REAL,

weight_kg REAL,

goal TEXT, \-- \'lose\' \| \'gain\' \| \'maintain\' \| \'recomp\'

activity_level TEXT, \-- \'sedentary\' \| \'light\' \| \'moderate\' \|
\'active\' \| \'very_active\'

created_at TEXT NOT NULL

);

CREATE TABLE foods (

id TEXT PRIMARY KEY,

name TEXT NOT NULL,

local_names TEXT, \-- pipe-separated alt names

category TEXT, \-- \'staple\' \| \'soup\' \| \'protein\' \| \'snack\' \|
\'drink\' \| \'breakfast\' \| \'fruit\' \| \'vegetable\'

serving_size_g REAL NOT NULL,

calories REAL NOT NULL,

protein_g REAL NOT NULL,

carbs_g REAL NOT NULL,

fat_g REAL NOT NULL,

fiber_g REAL,

sugar_g REAL,

sodium_mg REAL,

source TEXT, \-- citation for the nutrition data

verified INTEGER DEFAULT 0 \-- 0 = estimated, 1 = verified source

);

CREATE TABLE products (

id TEXT PRIMARY KEY,

barcode TEXT UNIQUE NOT NULL,

name TEXT NOT NULL,

brand TEXT,

manufacturer TEXT,

serving_size_g REAL NOT NULL,

calories REAL NOT NULL,

protein_g REAL NOT NULL,

carbs_g REAL NOT NULL,

fat_g REAL NOT NULL,

sugar_g REAL,

sodium_mg REAL,

ingredients TEXT

);

CREATE TABLE meal_logs (

id TEXT PRIMARY KEY,

user_id TEXT NOT NULL,

logged_at TEXT NOT NULL,

meal_type TEXT NOT NULL, \-- \'breakfast\' \| \'lunch\' \| \'dinner\' \|
\'snack\'

food_id TEXT,

product_id TEXT,

quantity_servings REAL NOT NULL DEFAULT 1,

synced INTEGER DEFAULT 0,

FOREIGN KEY (food_id) REFERENCES foods(id),

FOREIGN KEY (product_id) REFERENCES products(id)

);

CREATE TABLE exercises (

id TEXT PRIMARY KEY,

name TEXT NOT NULL,

category TEXT, \-- \'chest\' \| \'back\' \| \'legs\' \| \'shoulders\' \|
\'arms\' \| \'core\' \| \'cardio\'

difficulty TEXT, \-- \'beginner\' \| \'intermediate\' \| \'advanced\'

primary_muscles TEXT, \-- pipe-separated

secondary_muscles TEXT,

equipment TEXT,

instructions TEXT

);

CREATE TABLE workouts (

id TEXT PRIMARY KEY,

user_id TEXT NOT NULL,

started_at TEXT NOT NULL,

ended_at TEXT,

notes TEXT,

synced INTEGER DEFAULT 0

);

CREATE TABLE workout_sets (

id TEXT PRIMARY KEY,

workout_id TEXT NOT NULL,

exercise_name TEXT NOT NULL,

set_number INTEGER NOT NULL,

reps INTEGER,

weight_kg REAL,

rpe REAL,

duration_seconds INTEGER,

FOREIGN KEY (workout_id) REFERENCES workouts(id)

);

CREATE TABLE activity_logs (

id TEXT PRIMARY KEY,

user_id TEXT NOT NULL,

activity_type TEXT NOT NULL, \-- \'walk\' \| \'run\' \| \'cycle\' \|
\'other\'

started_at TEXT NOT NULL,

duration_minutes REAL NOT NULL,

distance_km REAL,

calories_estimated REAL,

synced INTEGER DEFAULT 0

);

CREATE TABLE water_logs (

id TEXT PRIMARY KEY,

user_id TEXT NOT NULL,

logged_at TEXT NOT NULL,

amount_ml REAL NOT NULL

);

Calorie burn is calculated with the standard MET formula: calories =
MET_value × body_weight_kg × duration_hours. Typical MET values: walking
≈ 3.5, running ≈ 9.8, cycling ≈ 7.5.

**7. Ghana Food Dataset**

**Structure:** matches the foods table above. Every entry is tagged
verified = 0 (estimated from a standard recipe) or 1 (from a cited
nutrition source) --- never presented as certain when it isn\'t.

**Sourcing, in order of use:**

1.  University of Ghana / Food Research Institute food composition data,
    where accessible --- the closest thing to an authoritative source
    for traditional dishes.

2.  FAO/INFOODS West African Food Composition Table --- publicly
    published, covers common regional ingredients.

3.  USDA FoodData Central --- fallback for generic ingredients (rice,
    oil, chicken) with no African-specific source yet.

4.  Manual estimation from standard recipes for anything not yet
    covered, clearly flagged verified = 0.

5.  Community submission with admin review (once there are real users)
    --- the realistic way this database grows past a few hundred
    entries.

**v1 starter target: 150--250 foods**, covering staples (jollof, waakye,
banku, fufu, kenkey, tuo zaafi, ampesi, kokonte, gari, yam), soups
(light soup, palm nut soup, groundnut soup, kontomire stew), proteins
(tilapia, grilled chicken, goat meat, boiled eggs), snacks (kelewele,
meat pie, bofrot, chinchinga), breakfast items (koko, tom brown, hausa
koko), common drinks, and everyday fruits/vegetables.

**8. Barcode/Product Dataset**

**Structure:** matches the products table above.

**Sourcing:**

1.  **Open Food Facts** --- an open, community-maintained product
    database that already includes real entries for many West African
    products. Best starting point; has a public API.

2.  **GS1 barcode registry** --- for verifying manufacturer information.

3.  **Manual entry from real packaging** for major local brands not yet
    covered elsewhere --- barcodes taken directly off physical products,
    not invented.

4.  **Community submission with review**, once there are real users
    scanning products that aren\'t in the database yet.

**v1 starter target: 30--40 products**, hand-verified from real
packaging: FanMilk (Fan Ice, Fan Yogo), Blue Band, Cowbell, Ideal Milk,
Peak Milk, Milo, Nescafé, Indomie Ghana, Bel Aqua, Verna, Frytol, Gino,
Tasty Tom, Titus and Geisha sardines, Golden Tree chocolate, Bigi
drinks, Coca-Cola/Fanta/Sprite (Ghana bottling), Vitamilk, Fortune Rice.

**9. Build Order**

1.  Project scaffold + local SQLite database + models.

2.  Seed the starter food dataset (Section 7); build search and meal
    logging.

3.  Build workout logging, exercise library, and PR tracking.

4.  Build activity logging with MET-based calorie estimates.

5.  Seed the starter product dataset (Section 8); build barcode/QR
    scanning, wired into meal logging.

6.  Add Supabase: auth, and sync for every table\'s synced flag.

7.  Ship v1. Everything in the Phase 2/3 columns of Section 4 gets
    scoped *after* this is in real use --- what people actually do with
    v1 should decide what\'s built next, not this document.

**10. Explicitly Out of Scope for v1**

AI food-photo recognition, GPS activity tracking, wearable integration,
social/leaderboards/challenges, trainer/coach dashboard,
budget/market-price meal planning, voice logging, 2FA/biometrics. All
real ideas, all deferred on purpose --- see Section 4 for where each
lands.
