# Lantern Island — Product & Build Spec

Version 1.0 · approved cast · character names and island name may still change

---

## 0. How to use this document

This spec is written for a developer working in VS Code with Claude (Claude Code or the Claude extension).

- **Read the existing codebase first.** Three simple games already exist (a cat dressing for the weather, a unicorn collecting diamonds, a cat jumping and picking things up). Build on top of them. Do not rewrite what works.
- **Plan before code.** For each phase in section 12, propose the design (mechanics, screens, data, assets) and get sign-off before implementing.
- **Stack-agnostic.** Follow the conventions already used in the repo.
- **Assets.** Approved character artwork and the expressions sheet are in `/assets` as SVG. `assets/characters/cast-lineup.svg` shows the whole cast together.
- **Section 13** contains a ready-to-use kickoff prompt.

---

## 1. Product summary

Lantern Island is a free, safe, educational game app for young children. Six animal friends from different parts of the world live together on a small island. Every game teaches something (a thinking skill) and every character models something (a feeling or social skill).

- **Target age:** 3–7 (to be confirmed)
- **Market:** global, with subtle Australian, Colombian and Vietnamese touches
- **Launch languages:** English, Spanish, Vietnamese

### Non-negotiables

- Free. No ads. No in-app purchases. Ever.
- No behavioural tracking, no third-party analytics or ad SDKs that track users.
- No streaks, no "come back tomorrow" notifications, no timers that create pressure, no progress that can be lost.
- Positive feedback only: celebrate effort, never punish mistakes with harsh sounds or "wrong" screens.
- Any link out of the app, settings or parent content sits behind a parental gate.
- Built to qualify for the **Apple App Store Kids Category** and **Google Play Families / Teacher Approved**, and to comply with **COPPA** (US) and GDPR-K (EU/UK).

---

## 2. Art style

**Style:** soft outline. Rounded shapes with a warm dark-brown outline (`#5A3A28`), flat colour fills, small textures (fur strokes, spots, stripes), side-on or three-quarter poses, a soft ground shadow under every character.

### Construction rules

| Rule | Detail |
|---|---|
| Outline | Warm dark brown `#5A3A28`, consistent weight across the cast |
| Poses | Side-on or three-quarter, so each animal's key feature shows (bills, snouts, tails) |
| Silhouettes | Every character has a **different body type** so they are recognisable even as shadows or small map icons |
| Eyes | Large, coloured iris, dark pupil, two white highlights (Pacho is the exception: sleepy half-closed eyes) |
| Cheeks | Pink blush |
| Texture | Light fur strokes, spots, stripes or patterns; never noisy |
| Ground shadow | Soft beige ellipse `#CFC4B8` under every character |
| Signature accessory | One accessory per character that makes them recognisable at a glance |

### Body types

| Character | Body type |
|---|---|
| Koko | Small and upright (sits like a little kangaroo) |
| Biggy | Slim and tall (elegant sitting cat) |
| Luna | Round pony on four stubby legs |
| Tobi | Plump seal-pup teardrop, chest raised |
| Tiko | Flat and wide (pancake platypus) |
| Pacho | Chunky loaf |

### Character palette (hex)

| Character | Main | Light | Dark / feet | Eyes | Accessory colours |
|---|---|---|---|---|---|
| Koko — quokka | #A68A6D | #E9D8C2 | #6E5643 | Brown #6B4A2B | Rash vest #F08A6E + #4FA3A5, zinc #6FC8F0, wattle #F4C744, board #FBF3E4, thongs #4FA3A5 / #F4C95D |
| Biggy — cat | White #FBF8F4 | Patches grey #9A9893, ginger #E3A66B | Stripes #6B6965 | Amber #D9B13B | Collar #EC6FA8, flower #F7B6D2, nose #E8A3A8 |
| Luna — unicorn | #EFE4F7 | Muzzle #FCE4EE | Hooves #B9A3E8 | Violet #8E6FD1 | Mane #F7A8C8 / #B9A3E8 / #9EDDCF, horn #F4C95D, scarf #4FA3A5 |
| Tobi — seal | #8FA7B8 | Belly #DCE6EC | Flippers #6E8798 | Deep blue-grey #2E3E4E | Headband #E8604C, bolt #F4C95D, sweatband #4FA3A5 |
| Tiko — platypus | #7A5539 | #CBB08E | Bill & feet #3F4A50 | Brown #6B4A2B | Goggles #9EDDF0 / #D9A441, sunnies #2E3A40 / #E8853C, board #4FA3A5 |
| Pacho — capybara | #CF9466 | Muzzle #A66B49 | Feet #A66B49 | Brown #5B3A22 (sleepy lid) | Mochila #FBF3E4 / #E8604C / #4FA3A5 / #F4C95D, bird #F4C95D |

Shared: outline #5A3A28, eye/line #2E221A, blush #F4A6A0, highlights #FFFFFF.

### Animal-recognition rules (keep in every pose)

- **Quokka:** wide cheeks tapering to a short pointed snout, small round ears, upright sitting posture, big feet, thin tail.
- **Cat:** large triangle ears with pink insides, whiskers, calico patches, curled tail.
- **Unicorn:** golden spiral horn, rainbow mane and tail, soft pink muzzle.
- **Seal:** no ears, puffy whisker pads, huge glossy eyes, fore-flippers, V-shaped tail flippers.
- **Platypus:** large flat charcoal duck bill clearly sticking out, webbed feet, flat scaled beaver tail.
- **Capybara:** boxy "loaf" head with flat top, small ears and eye set high, sleepy half-closed eye, broad dark muzzle, no tail.

### Expressions system

Seven expressions, built as **interchangeable layers** (brows, eye, mouth, cheeks, extras) on each character's head, so any friend can show any feeling. Reference: `/assets/expressions/` (shown on Koko).

| Expression | Eye | Brow | Mouth | Cheeks | Extra |
|---|---|---|---|---|---|
| Happy | Open, sparkly | None | Open smile, tongue | Pink | — |
| Sad | Open | Inner end raised | Frown | None | Tear |
| Worried | Smaller | Inner end raised | Wobbly line | None | Sweat drop |
| Frustrated | Flat-topped | Inner end lowered | Zigzag | Deep red | Red tension lines |
| Calm | Closed, curving down | None | Small soft smile | Light pink | — |
| Proud | Closed, arching up | None | Confident smile | Pink | Gold sparkles |
| Cheeky | Wink (">" shape) | None | Lopsided smile, tongue out | Pink | Small sparkle |

**Special rules**
- **Tiko's sunnies:** he wears them while skating and cruising. When he feels something (frustrated, proud, sad), he flips them up onto his head so his eyes show. This is also a fun animation moment.
- **Pacho's eye:** his default is sleepy and calm; for strong emotions his lid lifts to show the full eye.

---

## 3. The cast

All names provisional. Six friends at launch: three girls, three boys.

| | Koko | Biggy | Luna | Tobi | Tiko | Pacho |
|---|---|---|---|---|---|---|
| Animal | Quokka | Cat (calico) | Unicorn | Seal | Platypus | Capybara |
| Pronouns | She | She | She | He | He | He |
| Role | Warm-hearted host, surfer | Planner | Dreamer, painter | Brave, bouncy, funny | Tinkerer, skater | Calm one |
| Struggle | Hides her own sad feelings | Worries when plans change | Gets distracted | Big feelings come fast | Wants to give up when things fail | Too slow and laid-back |
| Growth | "It's okay to not be okay" | Flexibility | Focus and finishing | Stop, breathe, use words | Mistakes help me learn | Knowing when to hurry and when to wait |
| Catchphrase | "Everyone's invited!" | "First this, then that!" | "Ooh, shiny!" | "I've got this!" | "Let's try it another way!" | "No rush, friend." |
| Signature look | Surfboard, rash vest, zinc stripe, thongs, wattle flower | Pink flower collar, nose freckle | Paint-splattered scarf | Headband, sweatband, football | Goggles, tool belt, sunnies, skateboard | Woven mochila, bird on head |
| Home language | English | Vietnamese | Shared / "sparkle" voice (TBC) | Mixes words from everywhere | Borrows from every friend | Spanish |
| Sport | Surfing | Gymnastics (balance beam) | Ice skating | Football | Skateboarding | Swimming |
| Talent | Singing | Cooking | Painting | Drumming | Crafts and inventing from recycled bits | Guitar and storytelling |
| Learning (thinking) | Navigation, guiding play | Routines, sequencing, weather, food variety, tidying | Counting, colours, shapes, patterns | Movement, coordination | Problem-solving, cause and effect, early science | Nature, how plants grow |
| Feelings (social-emotional) | Kindness, sadness, empathy | Worry, coping with change | Focus | Frustration, calming down | Persistence, trying again | Patience, waiting your turn |

### Character notes

- **Koko (quokka):** main character and app guide. An Aussie surfer girl who introduces games, welcomes the child and notices when a friend is left out. Her zinc stripe and rash vest quietly model sun safety. Her **lantern** is her special Lantern Night item (she invites everyone), not something she carries every day. A yellow bucket hat can appear on non-surfing beach days.
- **Biggy (cat):** a mostly white calico with grey and ginger patches, amber eyes and a tiny freckle beside her nose. Loves routines, checklists and getting things "just right". The funny contrast of a big name on a slim, elegant cat is intentional.
- **Luna (unicorn):** creative and imaginative; her mane colours can shift with her mood (supports emotion naming).
- **Tobi (seal):** first to jump in and help; the funniest of the group. Owns the breathing moment ("big seal breaths").
- **Tiko (platypus):** "made of spare parts" running joke; keeps a "That didn't work… yet!" shelf. Built his own skateboard. Gadgets he builds appear in other friends' games.
- **Pacho (capybara):** everyone feels calmer near him. Carries a woven mochila (seeds for his garden, postcards from his cousins all over South America). A little yellow bird always rides on his head.

### Future friends (later seasons)

- **Titi — cotton-top tamarin (Colombia):** cheeky, competitive; owns fairness, turn-taking, losing well.
- **Sao — saola (Vietnam):** shy newcomer; owns belonging and nature.
- **Pacho's cousins (South America):** visiting characters; can introduce Portuguese.
- Possible: wombat (soft-hearted grump), spectacled bear (wise elder).

---

## 4. Language system

The island is an international community: friends from different places who share one common language but keep a little of home.

- **Shared language = the child's chosen app language** (English, Spanish or Vietnamese). The story must always be fully understandable in it.
- **Home words:** each character sprinkles in 2–3 words from their home language, always paired with a picture or action.
- **Friends teach each other:** e.g. Tobi tries Biggy's word, gets it wrong, Biggy helps, everyone laughs.
- **Word Jar:** words the child hears are collected in a jar at Koko's Treehouse; tapping a word replays it.
- **Voices:** native speakers per language. No exaggerated "foreign" accents.
- **Structure:** all text and audio keyed by string ID so more languages can be added.

### Starter word list

| Concept | English | Spanish | Vietnamese |
|---|---|---|---|
| Hello | Hello | Hola | Xin chào |
| Thank you | Thank you | Gracias | Cảm ơn |
| Friend | Friend | Amigo / Amiga | Bạn |
| Happy | Happy | Feliz | Vui |
| Sad | Sad | Triste | Buồn |

Native-speaker review required before shipping any language content.

---

## 5. The world: Lantern Island

The home screen **is** the island map. Children tap a place to enter its game.

| Zone | Owner | Games / activities | Key visual details |
|---|---|---|---|
| Koko's Treehouse (centre) | Koko | Home hub, Word Jar, Lantern Night progress | Big friendly tree, swing, noticeboard with drawings, lanterns in the branches, surfboard leaning on the trunk |
| Biggy's Cottage | Biggy | Dress for the weather, morning routine, colourful plate, the kitchen | Neat cottage, weather vane, clothesline, vegetable garden, checklist on the door |
| Luna's Rainbow Meadow | Luna | Diamond collecting, art studio | Flower meadow up to a crystal hill; flowers change colour with Luna's mood |
| Splash Cove | Koko and Tobi | Surf game, obstacle game, Calm Rock breathing, football | Beach, waves, rock pools, little lighthouse, finish line drawn in the sand |
| Tiko's Riverside Workshop | Tiko | Build-a-thing puzzles, experiments, skate ramp, instrument building | Wooden shed, water wheel, gadgets, "didn't work… yet!" shelf, homemade ramp |
| Pacho's Pond & Garden | Pacho | Garden game, swimming | Warm pond, garden beds, hammock between two trees |
| Misty Forest (locked) | Sao (later) | — | Across a broken bridge; Tiko fixes it in Season 2 |
| Mango Grove (locked) | Titi (later) | — | Hilltop grove |

### Subtle cultural touches

Touches live in plants, food, patterns, sound, accessories and the festival. Never flags, costumes or labelled "country" content. Each zone mixes influences.

- **Australia:** Koko's surfing, zinc stripe, rash vest, thongs and wattle flower; gum trees; sandy beach and rock pools; kookaburra laugh when an invention fails.
- **Colombia:** Pacho's Wayuu-style mochila; orchids; a hummingbird at the Treehouse feeder; painted base panels on Biggy's cottage (inspired by zócalos); hammock; light cumbia-style rhythm in the music; plantain and lulo in the garden.
- **Vietnam:** paper lanterns, bamboo and water wheel at Tiko's workshop, gently terraced hillside in Luna's meadow, lotus details; Biggy speaks Vietnamese.
- **Food in Biggy's kitchen:** a noodle soup, an arepa-style flatbread and a lamington-style cake alongside globally familiar food.

### Weather and time

- Weather and day/night are **in-game only**. Do not read the device location or call weather APIs.
- Day/night may follow the device clock (no permission needed).

---

## 6. Lantern Night (progress system)

Once a season, the island holds Lantern Night. Every activity the child plays helps get ready.

- Each friend has a job: Biggy plans, Luna collects colours and sparkles, Tobi delivers supplies, Tiko builds lantern frames, Pacho grows flowers for decorations, Koko invites everyone and carries the first lantern.
- Each completed activity **lights a lantern** on the island map.
- When enough lanterns are lit, a short celebration plays (singing, dancing, everyone says thank you in their own language).
- **Lanterns never go out.** No streaks, no expiry, no time limits.
- After the celebration, the next season begins.

---

## 7. Educational upgrade for the existing games

The learning must happen **inside the mechanic**, not as quizzes or pop-ups.

### Game 1 — Biggy dresses for the weather (existing cat dressing game)

- **Weather cause and effect:** sunny → hat and sunscreen; rain → boots and umbrella; cold → coat and scarf. If dressed "wrong", Biggy reacts in a gentle, funny way (shivers, gets splashed), then the child tries again. No "wrong" screen.
- **Morning routine mode:** wake up → brush teeth → get dressed → breakfast → pack bag. Teaches sequencing.
- **Colourful plate mode:** pick foods of different colours to fill a plate. Encourage variety and curiosity. **Never** label foods "good" or "bad"; never show calories, portions or weight-related content.
- **Words:** weather and clothing words spoken aloud.

### Game 2 — Luna collects diamonds (existing unicorn game)

- **Counting goals:** "collect 5 blue diamonds".
- **Simple addition:** "you have 3, find 2 more".
- **Patterns:** collect in a sequence (red, blue, red, blue).
- **Shapes:** later levels swap diamonds for circles, triangles and stars.
- **Colours:** named aloud on collection.

### Game 3 — Jumping and picking things up (existing cat jumping game)

Reassign to the cast: **Biggy** for a tidying version, or **Tobi** for an action version (decision in section 14).

- **Tidying:** pick up toys and put them in the right box.
- **Sorting:** recycling bins (paper, plastic, food scraps).
- **Early literacy:** collect letters to spell three-letter words (C-A-T).
- **Spatial words:** "over", "under", "up", "down" spoken as the character moves.

### Rules for all three

- **Adaptive difficulty:** step up after 3 successes in a row; step down after 2 struggles.
- **Short sessions:** each round completable in 2–5 minutes.
- **Parent tip:** optional card after a session, behind the parental gate (e.g. "Ask your child what they'd wear if it snowed").

---

## 8. New character games

| Game | Owner | Mechanic | Learning | Feelings |
|---|---|---|---|---|
| Surf's Up | Koko | Ride gentle waves, pop up on the board, collect shells | Timing, balance, counting | Confidence, encouraging friends |
| Obstacle Cove | Tobi | Jump rocks, dodge waves, reach the finish line | Coordination, timing | Persistence |
| Calm Rock | Tobi | Breathe in as a shape grows, out as it shrinks (about 4 slow breaths) | Body awareness | Calming down |
| Build-a-thing | Tiko | Connect parts to build a bridge, ramp or gadget for a friend | Problem-solving, cause and effect | Trying again after failure |
| What happens if… | Tiko | Float or sink, push or pull, mix colours | Early science | Curiosity |
| Pacho's Garden | Pacho | Plant, water, wait, watch it grow (seeds come from his mochila) | How plants grow | Patience |

Gadgets built in Tiko's game can appear in other games (e.g. a ramp in Tobi's cove), so the world feels connected.

---

## 9. Group activities (all friends together)

| Activity | Lead | What the child does | Learning |
|---|---|---|---|
| The island band | Koko sings, Tobi drums, Pacho guitar, Tiko builds instruments | Pick an instrument and play along | Rhythm, listening, cooperation |
| Art studio | Luna (painting), Tiko (collage) | Free drawing, colouring pages of the friends, collage | Creativity, colours, fine motor skills |
| The kitchen | Biggy, with Pacho bringing vegetables | Follow simple picture recipes | Sequencing, food variety |
| Dance party | Everyone | Copy each friend's signature move | Movement, memory, patterns |
| Puzzles | Rotating | Jigsaw scenes of the island and friends | Spatial reasoning |
| Sports Day (future season) | Everyone | Try each friend's sport | Coordination, fairness, losing well |

Art created by the child is saved **on the device only** and shown on the Treehouse noticeboard.

---

## 10. Learning design principles

Based on current paediatric guidance (AAP "5 Cs": Child, Content, Calm, Crowding out, Communication) and research on quality children's apps.

- **Active, not passive:** the child is always doing something.
- **Meaningful:** learning connects to real life (routines, weather, food, tidying, feelings, sun safety).
- **Feedback:** immediate, positive, specific ("You found 5 blue ones!").
- **Adaptive:** difficulty follows the child.
- **Co-play friendly:** activities a parent can enjoy alongside the child; parent tips support conversation.
- **Natural stopping points:** sessions end cleanly; nothing pulls the child to keep going.
- **No endless loops or autoplay** into the next game.

---

## 11. Safety, privacy and store compliance

- **Data:** collect nothing personal. No accounts for children. Progress stored locally on the device.
- **SDKs:** no third-party analytics, advertising or attribution SDKs. If crash reporting is needed, use a Kids-Category-compliant option with no personal data and confirm before adding.
- **Network:** the app should work fully offline.
- **Permissions:** no location, contacts, camera or microphone at launch. Any future feature needing these requires a separate privacy review.
- **Parental gate:** required for settings, parent tips, any external link and anything that leaves the app.
- **No chat, no user-to-user features, no user-generated content shared off the device.**
- **Store targets:** Apple Kids Category age band (likely "5 and under" or "6–8"; to be confirmed), Google Play Families programme and Teacher Approved review, and a Common Sense Media review after launch.
- **Privacy policy:** plain-language, parent-facing, published before submission.

---

## 12. Build phases

| Phase | Scope | Outcome |
|---|---|---|
| 1 | Restyle the three existing games in the soft outline style with Biggy and Luna; add educational layers (section 7); positive-feedback system; adaptive difficulty; layered expressions | Three upgraded, educational games |
| 2 | Island map home screen; Koko as guide; language system and Word Jar (EN/ES/VI); parental gate | One connected world |
| 3 | New character games (section 8) | All six friends have their own games |
| 4 | Lantern Night progress system and celebration | Season 1 story complete |
| 5 | Group activities (section 9) | Band, art studio, kitchen, dance, puzzles |
| 6 | Compliance pass, privacy policy, store submission | Ready for Kids Category / Families review |
| Later | Season 2 (Sao, bridge), Season 3 (Titi, Sports Day), Pacho's cousins and postcards | Ongoing story updates |

---

## 13. Kickoff prompt for Claude

Copy this into Claude Code (or the Claude VS Code extension) at the root of the repo:

```
Read LANTERN_ISLAND_SPEC.md and CLAUDE.md, look at the SVGs in /assets
(start with assets/characters/cast-lineup.svg and
assets/expressions/expressions-sheet.svg), then explore the existing codebase.

Context: this is a free, ad-free, safe educational game app for children aged
3–7. Three simple games already exist (a cat dressing for the weather, a
unicorn collecting diamonds, a cat jumping and picking things up). We are
building on top of them, not rewriting them. The cat is now Biggy (a calico)
and the unicorn is Luna.

Start with Phase 1 from section 12 of the spec:
1. Summarise the current architecture, how the three games are structured,
   and how assets, text and audio are handled.
2. Propose how to restyle the games in the soft outline style using the
   character SVGs (section 2), and how to add the educational layers in
   section 7, including adaptive difficulty and positive-only feedback.
3. Propose how to build expressions as interchangeable layers (eye, brow,
   mouth, cheeks, extras) so any character can show any of the seven
   expressions, including Tiko's sunnies flip and Pacho's sleepy lid.
4. List any risks, unknowns or questions.

Do not write code yet. Wait for approval of the plan.

Hard rules for everything you build (section 11): no ads, no in-app
purchases, no tracking or third-party analytics/ad SDKs, no personal data, no
location, no streaks or notifications, works offline, parental gate for
anything that leaves the app, positive feedback only.
```

---

## 14. Open decisions

- Final character names and island name.
- Confirmed age band (affects the Apple Kids Category band and learning goals).
- Luna's home language (Spanish, or a neutral "sparkle" voice).
- Who takes over the jumping game (Biggy for tidying, or Tobi for action).
- Whether the reference SVGs ship as-is or are redrawn by a designer in the same style.
- Voice actors per language.
- Funding model for a free, ad-free app (grant, sponsor, parent company, or portfolio project).

---

## Appendix — Asset list

| File | Contents |
|---|---|
| `assets/characters/cast-lineup.svg` | All six friends together |
| `assets/characters/koko-quokka.svg` | Koko, surfer girl |
| `assets/characters/biggy-cat.svg` | Biggy, calico cat |
| `assets/characters/luna-unicorn.svg` | Luna, unicorn |
| `assets/characters/tobi-seal.svg` | Tobi, seal pup |
| `assets/characters/tiko-platypus.svg` | Tiko on his skateboard |
| `assets/characters/pacho-capybara.svg` | Pacho with mochila and bird |
| `assets/expressions/expressions-sheet.svg` | All seven expressions (on Koko) |
| `assets/expressions/koko-*.svg` | Individual expression heads |

Artwork note: all character designs are original. External images were used only as general style and colour inspiration, never traced or copied.
