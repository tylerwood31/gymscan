# GymScan v2 — Product Design Document

**Date:** 2026-03-26
**Status:** Draft
**Author:** Tyler Wood

---

## 1. Product Vision

GymScan is a premium fitness app for traveling professionals (25-50) who want to stay active on the road but aren't fitness experts. They walk into unfamiliar hotel gyms, don't know what to do with random equipment, and often skip the workout entirely.

GymScan solves this in 30 seconds: scan the gym, get a personalized workout, track the session.

**Brand positioning:** Calm confidence. A concierge for your workout, not a drill sergeant. Premium but not intimidating. The app should feel like it was built by someone who actually works out in shitty hotel gyms.

**Target user:** Business traveler, 25-50, works out 2-4x/week at home, loses momentum on the road. Not a gym bro. Not an expert. Wants to "maintain what I built" and "feel good," not chase PRs.

---

## 2. Design Language

### Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Background | Near-black | #0E0E12 | Primary surface |
| Surface | Dark grey | #1C1C24 | Cards, sheets, inputs |
| Primary accent | Warm amber/gold | #E8A838 | CTAs, highlights, brand moments |
| Secondary accent | Muted teal | #4ECDC4 | Tags, badges, success states |
| Text primary | Cool white | #F5F5F7 | Headlines, body text |
| Text secondary | Grey | #8E8E93 | Captions, metadata |
| Destructive | Muted red | #E85454 | Errors, destructive actions |

**Why not blue?** Every fitness app is blue. Blue reads corporate and medical. Amber/gold reads premium and warm — closer to Equinox than a SaaS dashboard.

### Typography

- **Headlines:** SF Pro Display, Bold, tight tracking (-0.5)
- **Body:** SF Pro Text, Regular
- **Data/numbers:** SF Pro Rounded, Semibold (sets, reps, timers)
- Large type, generous spacing. Headlines should feel like a luxury brand.

### Motion Principles

- Subtle, purposeful. Nothing bounces. Nothing wiggles.
- Onboarding screens slide with slight parallax
- Equipment items animate in one-by-one (like a receipt populating)
- Workout exercises fan in like cards being dealt
- Rest timer pulses gently with amber glow
- Transitions: 0.3s ease-in-out default

### Photography & Video

- Real footage only. No illustrations, no 3D renders, no stock.
- Handheld hotel gym footage IS the brand (TikTok energy)
- Slightly desaturated, warm tone grading
- If it looks like Shutterstock, it's wrong

### Overall Feel

"You open the app and it feels like a concierge handed you a card that says 'we've got your workout handled.' Calm confidence. Not hype, not hustle."

---

## 3. Onboarding Flow

### Design Goals
- Complete in under 60 seconds
- One question per screen, single tap answers
- Analytics on every screen (screen_viewed, option_selected, time_on_screen, drop_off)
- No account required — everything stored locally until user chooses to sign in
- End with the value moment (first scan or demo)

### Screen 1: Welcome

Full-bleed looping video of a real hotel gym walk-through (handheld, warm grade, TikTok style). No stock photos.

```
[Looping hotel gym video background, slightly dimmed]

GymScan logo (amber/gold, minimal)

"Scan any gym.
Get a workout in seconds."

[ Get Started ]  (amber button, full width)
```

Analytics: welcome_viewed, get_started_tapped, time_on_screen

### Screen 2: Fitness Level

```
"How would you describe yourself?"

[ Just getting started     ]
[ I work out sometimes     ]
[ Pretty consistent        ]
[ Years of experience      ]

(Single tap advances to next screen)
```

Maps to: beginner / intermediate / consistent / advanced
Analytics: fitness_level_selected, value, time_on_screen

### Screen 3: Activity Preferences

```
"What do you enjoy?"
(Select all that apply)

[ Strength ]  [ Cardio ]  [ HIIT ]
[ Yoga & stretching ]  [ A bit of everything ]

                              [ Continue ]
```

Multi-select pills, amber border when selected.
Analytics: activities_selected, values[], time_on_screen

### Screen 4: Movements to Avoid

```
"Anything you'd rather skip?"

[ Heavy barbell lifts  ]  [ Jumping / impact ]
[ Overhead pressing    ]  [ Running          ]
[ None — I'm game for anything ]

Other: [free text field]

                              [ Continue ]
```

Multi-select + optional free text.
Analytics: avoidances_selected, values[], has_custom_text, time_on_screen

### Screen 5: Travel Goal

```
"When you're on the road, what's your goal?"

[ Stay active and feel good   ]
[ Maintain my routine          ]
[ Push myself wherever I am    ]
```

Single select. This sets the tone for every workout generated.
Analytics: goal_selected, value, time_on_screen

### Screen 6: Gender (Optional)

```
"One more thing — this helps us personalize exercises."

[ Male ]  [ Female ]  [ Skip ]
```

Casual, optional, no pressure. Affects exercise selection (e.g., no barbell bench for women by default).
Analytics: gender_selected, value_or_skipped, time_on_screen

### Screen 7: First Scan Prompt

```
"Ready to see the magic?"

[ Scan a gym now ]     (primary, amber)
[ Try a demo first ]   (secondary, outlined)
```

**"Scan a gym now"** → goes to camera/video capture flow.
**"Try a demo first"** → plays a pre-recorded hotel gym walk-through video (like the TikTok reference), runs the real scan pipeline on it, shows equipment detection → workout generation. Full value experience without being at a gym.

Analytics: first_scan_choice (scan_now / demo), time_on_screen

### Onboarding Analytics Dashboard

Track these funnels:
- Welcome → Completed onboarding (target: 80%+)
- Per-screen drop-off rates
- Onboarding → First scan initiated
- First scan → First workout generated
- First workout → Workout completed
- Workout completed → Sign in
- Sign in → Premium conversion

---

## 4. Authentication

### Stack
- **Supabase Auth** — Sign in with Apple, Google, email
- **Sign in with Apple required** (App Store policy for apps with third-party auth)

### When Auth Happens

Auth is deferred until after the first value moment:

1. Onboarding profile (anonymous, SwiftData)
2. First scan (anonymous)
3. First workout generated + completed (anonymous)
4. "Save this workout and gym?" → **Sign in with Apple** prompt
5. Account created in Supabase, local profile synced

If user never signs in, everything works locally via SwiftData. Auth unlocks cloud sync, workout history across devices, and premium features.

### Supabase User Model

```sql
users (managed by Supabase Auth)
  - id (uuid)
  - email
  - created_at

user_profiles
  - user_id (fk → users.id)
  - fitness_level (text: beginner/intermediate/consistent/advanced)
  - preferred_activities (text[])
  - movements_to_avoid (text[])
  - travel_goal (text: feel_good/maintain/push)
  - gender (text, nullable)
  - onboarding_completed_at (timestamp)
  - created_at
  - updated_at
```

---

## 5. Paywall & Pricing

### Placement

The paywall appears after the first free scan + workout cycle:

1. First scan → free
2. First workout → free
3. Complete workout → endorphins flowing → "Save this gym?" → sign in
4. Second scan → **Paywall**

The user has experienced the full value before being asked to pay. Peak satisfaction, not peak frustration.

### Paywall Screen Design

```
[Their actual completed workout, faded in background]

"You just crushed it."

Unlimited gym scans
Save gyms you visit again
Workouts that learn how you train

[ $9.99/month          ]
[ $59.99/year     ★ BEST VALUE  ]  (pre-selected, amber)
[ $99.99 lifetime               ]

[Restore Purchase]    [Not now]
```

- Dark background, amber accent
- Personal — shows their actual workout, not a generic promo
- Annual plan pre-selected (70%+ revenue from annual in industry benchmarks)
- Lifetime option prominent — addresses subscription fatigue from Reddit research
- Easy dismiss, no dark patterns, no guilt copy

### Pricing Rationale

| Plan | Price | Effective Monthly | Why |
|------|-------|-------------------|-----|
| Monthly | $9.99 | $9.99 | Below Fitbod ($8 annual-only) and Alpha Progression ($13) on monthly basis |
| Annual | $59.99 | $5.00 | The real target. Competitive, feels like a deal vs monthly |
| Lifetime | $99.99 | Decreasing | Catches subscription-fatigued users. At $0.09/scan, needs 1,111 scans to break even on API costs |

### Payment Stack

**RevenueCat** handles:
- App Store subscription management
- Receipt validation
- Entitlement checking (is this user premium?)
- Analytics (MRR, churn, trial conversion)
- Lifetime purchase handling

Free up to $2.5k MTR. RevenueCat's paywall SDK can also handle A/B testing different paywall designs.

---

## 6. Free vs Premium Features

| Feature | Free | Premium |
|---------|:----:|:-------:|
| Gym scans | 1 total (first scan) | Unlimited |
| Workout generation | 1 (from first scan) | Unlimited |
| Session tracker + rest timer | Yes | Yes |
| Onboarding profile | Yes | Yes |
| Save gym profiles | No | Yes |
| Workout history | No (ephemeral) | Yes (synced) |
| Streak tracking | No | Yes |
| AI personalization (learns over time) | No | Yes |
| Cardio modes (tabata, intervals) | No | Yes |
| Recent workout context (no repeat sessions) | No | Yes |
| Travel mode push notifications | No | Yes |
| Apple Health integration | No | Yes |
| Offline saved workouts | No | Yes |

The free tier is generous enough to prove the value (full scan + full workout + session tracker) but limited enough that anyone who travels regularly needs premium.

---

## 7. Dynamic Workout Personalization

### User Profile → Prompt Injection

The onboarding data feeds directly into the workout generation prompt as a `## User Profile` section:

```
## User Profile
- Fitness level: intermediate
- Enjoys: strength, HIIT
- Avoids: heavy barbell lifts, running
- Goal: maintain routine while traveling
- Gender: female
- Recent workouts (last 7 days):
  - 2 days ago: chest, triceps, shoulders (Marriott Denver, 30 min)
  - 5 days ago: legs, core (Home gym, 45 min)

Adapt exercise selection, rep ranges, coaching language, and volume
to match this profile. Avoid prescribing movements in the "avoids" list.
Avoid overlapping primary muscle groups from the last 48 hours.
Prioritize muscle groups not hit in the last 5 days.
```

### How Personalization Changes Output

**Beginner woman + "feel good" + avoids barbell:**
- Fewer exercises (5-6 for 45 min)
- Longer rest periods (90s)
- Dumbbell and machine-based movements only
- Encouraging coaching notes ("you've got this")
- No barbell compounds, no complex movements

**Consistent man + "maintain" + no restrictions:**
- Moderate volume (7-8 for 45 min)
- Standard hypertrophy ranges
- Full exercise variety including barbell
- Practical coaching notes ("control the descent")
- "Maintenance mode" framing

**Advanced + "push" + no restrictions:**
- Higher volume (9-10 for 45 min)
- Compound-heavy, supersets where equipment allows
- Technical coaching cues
- Shorter rest between isolation work

### Recent History Context

The backend pulls the user's last 7 days of completed workouts before generating. This prevents:
- Same muscle groups two days in a row
- Same exercises repeating within the same week
- Imbalanced weekly volume (all upper, no lower)

The prompt receives:
```
## Recent History (last 7 days)
- Mar 25: chest, triceps (Marriott Denver) — Dumbbell Bench Press, Cable Fly, Tricep Pushdown, Overhead Extension
- Mar 23: legs, core (Home gym) — Goblet Squat, RDL, Lunges, Cable Woodchop
```

And the constraint:
```
Do not repeat any exercise from the last 48 hours.
Minimize repeating exercises from the last 7 days — substitute variations.
Prioritize: back, shoulders, biceps (not hit recently).
```

---

## 8. Travel Mode & Push Notifications

### Significant Location Change Detection

iOS provides `CLMonitor` for significant location changes — low battery, no precise GPS, triggers when user moves ~500m+ or changes cell tower.

**Flow:**
1. During onboarding (or later in settings): "Want a reminder when you're traveling?"
2. If yes, request "When In Use" location permission
3. App registers for significant location changes
4. When user moves 50+ miles from their "home" location → mark as "traveling"
5. Send push notification: "Looks like you're on the road. Hotel gym nearby?"
6. Tapping opens the app with "Scan a Gym" ready to go

**Privacy-first:**
- No precise tracking, no background GPS
- Home location is stored on-device only, never sent to server
- User can disable anytime in settings
- Clear explanation during permission request: "We'll only check if you've traveled — never your exact location"

### Push Notification Strategy

| Trigger | Message | When |
|---------|---------|------|
| Significant location change (50+ mi) | "On the road? Scan a gym in seconds." | Within 2 hours of travel detection |
| Morning at travel location | "Good morning. Ready to find a workout?" | 7-8 AM local time, day 2+ of travel |
| 3 days since last workout | "15 minutes counts. Quick scan?" | Non-intrusive time |
| Streak at risk | "5-day streak going strong. Keep it alive?" | Evening before streak breaks |

Max 1 notification per day. Never spam.

---

## 9. Analytics & Tracking

### Critical Events

**Onboarding funnel:**
- onboarding_started
- onboarding_screen_viewed (screen_name, screen_index)
- onboarding_option_selected (screen_name, value)
- onboarding_completed (total_time_seconds)
- onboarding_abandoned (last_screen, time_on_last_screen)

**Core loop:**
- scan_initiated (source: home/demo/notification)
- scan_completed (equipment_count, duration_seconds)
- equipment_confirmed (items_added, items_removed, items_toggled_off)
- workout_generated (exercise_count, duration_selected, muscles_selected)
- workout_started
- exercise_completed (exercise_name, sets_completed)
- rest_timer_skipped (count per session)
- workout_completed (total_time, exercises_completed, exercises_skipped)
- workout_abandoned (last_exercise, time_in_session)

**Monetization:**
- paywall_shown (trigger: second_scan/save_gym/history)
- paywall_dismissed
- purchase_initiated (plan: monthly/annual/lifetime)
- purchase_completed (plan, price, revenue)
- trial_started (if added later)
- subscription_cancelled

**Retention:**
- app_opened (days_since_last_open, is_traveling)
- notification_received (type)
- notification_tapped (type)
- gym_saved
- gym_revisited (days_since_last_visit)
- streak_length_updated (new_length)

### Analytics Stack

**Mixpanel or PostHog** for event analytics. Both have generous free tiers. PostHog is open-source and can self-host if needed.

RevenueCat provides subscription analytics (MRR, churn, LTV) out of the box.

---

## 10. Supabase Schema (Full)

```sql
-- Auth handled by Supabase Auth (users table auto-managed)

-- User profile from onboarding
create table user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade unique,
  fitness_level text not null default 'intermediate',
  preferred_activities text[] not null default '{}',
  movements_to_avoid text[] not null default '{}',
  travel_goal text not null default 'feel_good',
  gender text,
  home_latitude double precision,
  home_longitude double precision,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Scanned gyms
create table gyms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text,
  latitude double precision,
  longitude double precision,
  equipment jsonb not null default '[]',
  scan_frame_count int not null default 0,
  created_at timestamptz not null default now()
);

-- Generated workouts
create table workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  gym_id uuid references gyms(id) on delete set null,
  target_muscles text[] not null,
  duration_minutes int not null,
  exercises jsonb not null default '[]',
  user_profile_snapshot jsonb, -- profile at time of generation for prompt debugging
  completed boolean not null default false,
  completed_at timestamptz,
  exercises_completed int[] default '{}',
  created_at timestamptz not null default now()
);

-- Streak tracking
create table streaks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade unique,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_workout_date date,
  updated_at timestamptz not null default now()
);

-- Analytics events (optional — can use Mixpanel/PostHog instead)
create table analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  anonymous_id text, -- for pre-auth tracking
  event_name text not null,
  properties jsonb default '{}',
  created_at timestamptz not null default now()
);

-- Indexes
create index idx_workouts_user_created on workouts(user_id, created_at desc);
create index idx_gyms_user on gyms(user_id);
create index idx_gyms_location on gyms using gist (
  ll_to_earth(latitude, longitude)
) where latitude is not null;
create index idx_analytics_user_event on analytics_events(user_id, event_name, created_at desc);
```

---

## 11. Cardio & HIIT Modes (Premium)

Beyond strength workouts, premium users get:

### Tabata Mode
- 20s work / 10s rest, 8 rounds = 4 minutes per exercise
- Uses available equipment or bodyweight
- Built-in interval timer with audio cues
- Example: "Kettlebell Swings → Burpees → Dumbbell Thrusters → Mountain Climbers"

### Treadmill Intervals
- Structured speed/incline intervals for the hotel treadmill
- 20/30/45 min options
- "Walk → Jog → Sprint → Walk" with specific speeds based on fitness level
- Visual pace guide on screen

### Bodyweight Circuit
- No equipment needed — for the truly terrible hotel gyms
- Or hotel room workouts
- Follows same personalization rules (fitness level, avoidances)

These modes use the same prompt architecture — user profile + available equipment (or "none") + duration → structured workout.

---

## 12. Widget & Apple Health

### iOS Lock Screen Widget
- Shows: current streak count, days since last workout, or "Scan a gym" quick action
- Small widget: streak number + flame icon
- Medium widget: streak + last workout summary + "Scan" button

### Apple Health Integration
- Write completed workouts as "Traditional Strength Training" activities
- Include: duration, calories estimated, exercises
- Read: nothing for MVP. Later: resting heart rate for recovery suggestions.

---

## 13. Implementation Priority

### Phase 1: Design System + Onboarding (build first)
- Implement color palette, typography, motion system
- Redesign all existing screens with new brand
- Build 7-screen onboarding flow with analytics
- Build demo scan flow (pre-recorded video → real API → workout)
- Local user profile storage (SwiftData)

### Phase 2: Auth + Supabase
- Supabase project setup, schema migration
- Sign in with Apple + Google
- Profile sync (local → cloud on sign in)
- Gym and workout cloud storage

### Phase 3: Paywall + RevenueCat
- RevenueCat integration
- Paywall screen (3 tiers)
- Entitlement gating (scan count, save gym, history)
- Restore purchases

### Phase 4: Dynamic Personalization
- User profile injection into workout prompt
- Recent workout history context
- Exercise avoidance enforcement
- Gender-aware exercise selection

### Phase 5: Retention Features
- Streak tracking
- Travel mode (significant location changes)
- Push notifications
- Apple Health write-back
- Lock screen widget

### Phase 6: Cardio Modes
- Tabata timer
- Treadmill interval programs
- Bodyweight circuits

---

## 14. Open Questions

1. **Exercise visuals** — In-app exercise demonstrations. Options: free API (Wger.de), licensed GIF library, or AI-generated illustrations. Decided against YouTube links (sends users off-app). Needs further research.
2. **Offline mode** — How much to cache locally? Full workout generation requires API. Could pre-generate 2-3 workouts per saved gym for offline use.
3. **Community features** — Saved gym ratings, community-sourced hotel gym data. High value but significant scope. v3 candidate.
4. **Apple Watch** — Rest timer on wrist during workout. High user value, moderate build effort. v2 or v3.
5. **A/B testing paywalls** — RevenueCat supports this natively. Should test lifetime vs no-lifetime, different price points, different copy.
