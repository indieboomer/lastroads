# The Last Roads - NPC regeneration guide

Version 1.1 | 8 November 2026 | Language: English

## 1. Decision

Use Diego Velazquez as the principal reference for believable faces, physical weight and economical painting. Use Francisco de Zurbaran for the cleric's devotional composure and substantial cloth. Use Joachim Beuckelaer selectively for the innkeeper's everyday humanity and practical dress.

The goal is a coherent cast of people from an alternative late-Renaissance / early-Baroque world. Preserve warmth, wit and colour. Do not turn every character into an elderly, miserable figure. Beauty is allowed; identical idealised faces are not.

The accompanying PDF contains the supplied originals and an AI-generated direction study. The painted study is a visual proposal, not historical art or a production sprite sheet. Its waist-up framing, changed poses, dark background and baked lighting must NOT replace the originals' technical layout.

## 2. Reference hierarchy

1. Existing asset and actual game import settings: authoritative for role, pose, framing, dimensions and animation contract.
2. Approved character direction in the lookbook: authoritative for changes to face, expression, costume treatment and material hierarchy.
3. Historical paintings: guidance for anatomy, colour relationships, handling of cloth and edges, not literal costume copies or background templates.

### Historical reference links

- Velazquez, *Christ in the House of Martha and Mary*: https://www.nationalgallery.org.uk/paintings/diego-velazquez-christ-in-the-house-of-martha-and-mary
- Zurbaran, *Saint Margaret of Antioch*: https://www.nationalgallery.org.uk/paintings/francisco-de-zurbaran-saint-margaret-of-antioch
- Beuckelaer, *The Four Elements: Fire*: https://www.nationalgallery.org.uk/paintings/joachim-beuckelaer-the-four-elements-fire

These are museum reference pages, not included production textures. Preserve the provenance of any reference or generated output used by the project. The generated lookbook portraits are not reproductions attributed to these painters.

## 3. Shared visual grammar

### Faces and bodies

- Natural adult eye sizes; restrained catchlights, eyelash emphasis and iris contrast.
- Individually shaped noses, mouths, chins and brows. Subtle asymmetry, not deliberate disfigurement.
- Complexions contain warm and cool areas. Avoid plastic skin, excessive sharpening and uniform brown shading.
- Hands look capable of holding the prop. Respect grip, finger count and prop geometry.
- Body mass has weight. Cloth hangs from shoulders, waist and elbows; anatomy is not a bodybuilding diagram.
- Preserve each character's age category and emotional role. The Sister remains a young adult; Mara remains welcoming.

### Painting and detail

- Give faces, hands and the role-defining prop the strongest attention.
- Use broad cloth planes and selected folds. Let quiet surfaces remain quiet.
- Reduce repeated embroidery, tiny buckles, leather scratches and decorative straps.
- Use both defined and softer internal edges. Keep the outer silhouette clean for compositing.
- Avoid a uniformly coarse brush texture, canvas overlay, artificial craquelure, fake aged varnish and sepia filter.
- Maintain distinct costumes: ochre for Mara, earth/leather for Osric, burgundy for Rook, muted blue and ivory for the Sister.

### Lighting for actual assets

The portraits demonstrate form; production sprites need more forgiving lighting. Use restrained soft directional modelling with readable shadow detail. Do not bake a large rectangular room background or a cast ground shadow into the sprite. Avoid strong rim lights that imply a different environment.

Lantern and candle remain identifying objects. Decide from the existing renderer whether their glow is separate, shader-driven or baked. Do not bake a large orange halo if the game already supplies that light. Do not erase their warm visual accents.

### Adult sensuality: selective character direction

This is a game for mature audiences. Selected clearly adult secular women may express earthy, festive, Renaissance-inspired sensuality. This is character direction, not a universal treatment of female NPCs. Assign it explicitly by character; do not infer availability, morality or sexuality from ancestry, body type, occupation or religion. The Sister is explicitly excluded: retain her devotional composure, covered costume and non-sexual presentation.

Mara is the principal expression of this direction. She is visibly middle-aged, self-possessed and markedly more sensual than the initial lookbook study. Preserve her generous build: a full bust, soft upper arms, broad hips and natural belly. Use a lower, broad square neckline with visible upper chest and tasteful cleavage, a supportive fitted bodice over linen, and a substantial skirt. Keep opaque coverage over breasts and lower body. Cloth should compress and drape credibly; do not replace weight with a tiny fantasy waist or inflated anatomy.

Her appeal comes from frank eye contact, a knowing asymmetric smile, flushed cheeks and relaxed confidence. She enjoys company, food, wine and flirtatious humour; she remains a capable innkeeper with agency. A slightly loosened linen neckline and a suggestive but ordinary tavern gesture can convey more than ornamental lingerie. Within the current asset pass preserve her pose and lantern hand; express the change primarily through face, neckline and cloth. A changed hip stance or leaning pose requires a separate pose revision and technical validation.

For other explicitly designated adult secular women, vary the expression: a witty smile, exposed shoulders, a generous neckline, a confident stance or tactile fabric. Do not give every woman Mara's costume, proportions or personality. Preserve older bodies, individual faces and different forms of attractiveness.

The target is bawdy human warmth and bodily abundance, not a modern glamour shoot. Avoid pornographic framing, explicit sexual activity, exposed nipples or genitals, fetish lingerie, latex, contemporary pin-up posing, exaggerated anatomy and childlike facial styling. Sensuality must remain legible in the full-body sprite, without a camera crop that isolates breasts or buttocks. The existing Mara study establishes paint handling only; it understates the revised sensual direction and must not limit it.

## 4. Per-character direction

| Character | Keep | Change | Reject |
|---|---|---|---|
| Mara | Mature, full-bodied innkeeper; linen cap, ochre dress, lantern, practical accessories; welcoming nature | Knowing flirtatious smile and direct gaze; visibly fuller bodily presence; lower square neckline with tasteful cleavage; supportive fitted bodice; simpler apron | Perfect advertising smile, doll eyes, luxurious brocade covering every surface, hostility replacing warmth, modern lingerie, exaggerated anatomy |
| Osric | Older grey-haired bearded smith; hammer, leather apron, work shirt; strength | Heavy worker's torso and broad hands; less idealised face; economical wear marks; fewer redundant tools where silhouette allows | Fitness-model anatomy, fashionable salon hair, making every cloth edge shredded |
| Rook | Adult swordsman; burgundy, hat, feather, rapier and cloak; alert presence | More individual wary face; less extravagant trim; coherent tailoring; simpler material hierarchy | Generic romantic hero, huge pirate caricature, excessive belts, oversized eyes |
| Sister | Young adult female Christian cleric; veil, blue/ivory garments, candle and visible cross | Natural eye size, fuller facial structure, calm compassion, heavy cloth, sparse gold accents | Childlike face, princess styling, porcelain skin, replacing cross with fantasy emblem, ageing her into a different character, eroticised costume or pose |

The lookbook study still idealises Osric somewhat. The final production pass should improve individuality without changing his role or making him a caricature. Rook's production silhouette stays aligned to the existing sheet: reducing hat size is a separate approved redesign, not an automatic change during style transfer.

## 5. Preserve the asset contract

Inspect the actual files and project before editing. Do not infer frame size, pivot, alpha mode or texture filtering from a chat preview. Record per asset:

- Source filename and hash; canvas width and height.
- Frame count, rectangles, order and state labels from the project.
- Ground baseline, pivot and bounding box.
- Transparent padding and attachment locations.
- Import settings, colour space, alpha handling, filtering and atlas use.

The supplied previews show open-eye and closed-eye versions side by side. Confirm their usage in code. If the second frame is a blink, only eyelids and the minimum surrounding skin change; pose, prop, clothing, face position and lighting remain identical.

Retain full-body framing, camera angle, facing, prop hand, relative scale and ground contact. Do not mirror the character. Do not crop hat, feather, weapon, candle, lantern or feet. Do not turn a production sheet into a labelled presentation board.

Do not regenerate every frame independently. Approve one master frame, derive the blink by a tightly constrained eye-region edit, then assemble to the recorded layout. Keep source art separate from the final atlas. If exact preservation is not achieved, reject or repair before replacing the live asset; a successful image-generation call is not technical acceptance.

## 6. Ready-to-use prompt system

Attach the ORIGINAL sheet as the geometry/pose reference and the matching LOOKBOOK portrait as the art-direction reference. Clearly label their roles. Generate one character at a time. Use the shared prompt, one character block and the required output block below.

### Shared style prompt

```text
Restyle this existing NPC for The Last Roads, an alternative late-Renaissance and early-Baroque RPG. The original asset is authoritative for full-body pose, proportions of the occupied frame, camera, facing, prop placement and silhouette envelope. The approved painted portrait is a reference for artistic direction only, not its crop, pose or background.

Use the naturalistic character observation of Diego Velazquez: individual adult facial anatomy, believable body weight, expressive practical hands, restrained warm and cool flesh tones, economical oil-painted forms and selective internal edges. Broad substantial cloth folds, quiet surfaces, limited ornament, coherent earth colours with the character's existing colour accent. Natural eye sizes and modest highlights. Preserve the person's role, age category and recognizable costume identity while removing idealised generic fantasy treatment.

Readable soft modelling suitable for a game sprite, lifted shadow detail and a clean cutout silhouette. Face, hands and role-defining prop receive priority. No anime, doll face, beauty-advertisement smile, bodybuilding anatomy, glossy concept-art finish, uniform microtexture, fake canvas overlay, craquelure, sepia filter, dramatic blacked-out face or added background.
```

### Mara character block

```text
Mara is unmistakably a middle-aged adult innkeeper: auburn hair beneath a linen cap, ochre dress, practical apron and brass lantern. Make her markedly more sensual than the earlier portrait study, with earthy festive warmth and self-possessed flirtation. Preserve her full bust, soft upper arms, broad hips and natural belly. A lower broad square neckline reveals upper chest and tasteful cleavage; an opaque linen chemise and supportive fitted bodice keep breasts covered. Heavy cloth follows believable bodily weight; no tiny fantasy waist or exaggerated anatomy.

Give her direct knowing eye contact, a lively asymmetric smile, warm flushed cheeks and the confidence of a woman who enjoys company and bawdy humour. Keep a mature individual face and practical hands. Use the shared Old Master paint handling, with Beuckelaer as supporting inspiration for everyday life, not as a mandate to copy a specific pose. Simplify ornament. Retain the original full-body pose, lantern hand, silhouette envelope and useful accessories. No modern lingerie, glamour retouching, explicit nudity, sexual act or isolated body-part framing.
```

### Osric character block

```text
Osric is an older grey-haired, bearded blacksmith in a leather apron and off-white work shirt, holding his existing hammer. Retain strength, age and quiet dignity. Make his face individual rather than conventionally handsome, with a substantial nose, tired eyes and natural asymmetry. Give him a worker's heavy torso and broad practical hands rather than sharply defined bodybuilding muscles. Use larger selective areas of leather wear. Preserve the exact hammer grip and original production silhouette; do not substitute the study portrait's pose.
```

### Rook character block

```text
Rook is a lean adult swordsman with dark hair, a burgundy broad-brimmed feathered hat, burgundy doublet, dark cloak and rapier. Preserve his recognizable equipment and original silhouette envelope. Give him an individual, watchful, slightly wary face rather than romantic hero perfection. Natural eye size and understated expression. Render burgundy as rich cloth colour, not glossy red leather. Simplify decorative trim and redundant surface detail. Maintain convincing period tailoring and readable hand-to-rapier contact.
```

### Sister character block

```text
The Sister is a young adult Christian female cleric with an ivory veil, muted blue mantle, candle and a clearly visible Christian cross. Take specific inspiration from Francisco de Zurbaran's substantial textiles, composed figures and devotional dignity. Preserve youth and compassion, but use natural smaller eyes, a substantial chin, an individual nose and a calm attentive expression. Heavy broad cloth folds, restrained gold edging, fewer embroidered motifs. Keep the cross recognizable and distinct from costume trim. Do not turn her into a child, princess, elderly nun or fantasy goddess. Preserve the original candle pose and hands. She is explicitly excluded from the sensual direction: no lowered neckline, seductive expression, erotic pose or sexualised costume treatment.
```

### Master-frame output block

```text
Deliver one full-body OPEN-EYES master on a genuinely transparent background. Preserve the original frame's aspect ratio, pose, orientation, feet baseline and safe margins. No text, labels, border, comparison layout, background, floor or baked checkerboard. Keep every identifying prop fully inside the frame. Technical dimensions and alignment must be validated against the source after generation; do not treat this text request as proof of exact pixel preservation.
```

### Blink-edit prompt

```text
Use the approved open-eyes master as the sole edit target. Produce its closed-eyes blink frame. Change only the eyelids and the minimum adjacent skin needed for a natural blink. Preserve every other pixel where possible: head position, expression outside the eyes, mouth, hands, costume, props, silhouette, lighting, transparency, dimensions and ground baseline. Do not bow the head or relax the whole face. No repainting or redesign outside the eye regions. Reject frame drift during technical validation.
```

## 7. Regeneration sequence

1. Inspect the current asset import and animation code. Save an untouched backup and record the contract.
2. Use the Sister to validate shared paint handling and technical continuity. Also approve a separate Mara pilot for the revised adult sensual direction; approval of the Sister does not approve Mara's character treatment.
3. Generate one open-eye master; review beside the original and at intended in-game size.
4. Confirm the look before deriving the blink. Inspect an animated alternation for face, prop and silhouette drift.
5. Validate transparency and placement; assemble a versioned sheet using the actual project frame layout.
6. Test in a small scene in daylight, warm indoor light and night, using every currently supported colour look.
7. Apply the same process to Mara, Osric and Rook. Use the approved pilot to maintain shared lighting and paint handling.
8. Replace live references only after validation. Keep filenames or update references atomically; record old-to-new mapping and rollback path.

Do not change gameplay, collision, dialogue, character identity or scene scale during this asset-only pass. If a better silhouette requires changing the frame envelope or attachments, propose that separately and test the consuming scene.

## 8. Pixel-art compatibility

The approved painted master is a source illustration, not automatically pixel art. Maintain large forms that survive reduction. At intended in-game size, eyes, nose, hands, prop and costume colour should remain distinct without thin embroidery.

For an actual pixel-art variant, choose a fixed pixel height, simplify clusters, control palette and use nearest-neighbour scaling. Inspect at native size and an integer enlargement. Avoid merely adding canvas noise or a low-resolution screen filter. Confirm the existing renderer's filtering expectations before changing imports.

Use shared palette principles rather than one brown ramp. Preserve light/dark separation around dark skin, navy cloth and deep shadows. The cross must remain readable through shape and contrast. No game rule may depend on whether a cross is visible in the sprite.

## 9. Acceptance checklist

### Artistic

- [ ] The cast looks coherent and recognisably period-inspired without looking identical.
- [ ] Natural adult facial proportions; individuality without caricature.
- [ ] Mara is clearly middle-aged, warm, self-possessed and visibly more sensual than the earlier study; her neckline and bodily weight communicate the revision.
- [ ] Sensual treatment is assigned selectively to designated adults; the Sister remains non-sexual and devotionally composed.
- [ ] Osric remains capable and Rook alert.
- [ ] No explicit exposure, sexual act, exaggerated anatomy or modern lingerie; full-body readability and individual character survive.
- [ ] Strong value hierarchy and distinct costume accents; no universal sepia.
- [ ] Cloth has weight; excessive embroidery and surface noise are reduced.
- [ ] Hands and prop grips are anatomically credible.
- [ ] The Sister's cross survives both lighting changes and reduction.

### Technical

- [ ] Actual dimensions, frame rectangles, order and baseline match the recorded contract.
- [ ] Alpha is genuine; no opaque rectangle, matte fringe, checkerboard or detached edge fragments.
- [ ] Composite over light, dark and saturated backgrounds to expose edge contamination.
- [ ] Blink changes only the intended eye region; no body, prop or face-position jitter.
- [ ] No clipping at sprite bounds, atlas neighbours or mip levels used by the project.
- [ ] Import settings and attachment coordinates remain valid.
- [ ] Test at actual screen size, not only in enlarged portraits.
- [ ] Check all currently supported colour looks and day/night conditions.
- [ ] Backups, provenance, prompts and generation settings are recorded.

## 10. Handoff instruction for a coding agent

Read this guide, the lookbook and the existing asset importer before editing. Start with an audit, a Sister technical/style pilot and a separate Mara sensuality pilot before a batch overwrite. Follow the revised written Mara direction over the earlier, more restrained study portrait. Use available image-generation/editing tools for the repaint; code alone is not a substitute for the approved painting style. Use deterministic scripts for validation and atlas assembly where supported. If image tooling is unavailable, prepare the exact inputs and prompts and report that dependency rather than inventing regenerated assets. Return comparison screenshots, an animated blink check, validation results and an asset mapping. Keep production originals until the new assets pass review.
