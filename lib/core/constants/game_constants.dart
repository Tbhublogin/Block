library;

/// Global gameplay constants: grid size, scoring values, spawn odds.

/// Side length of the square game grid (PRD 5.1: "Standard 8x8 grid,
/// configurable constant"). Board logic and widgets must read this instead
/// of inlining 8.
const int gridSize = 8;

/// Number of pieces shown in the tray at once (PRD 5.2: "Piece tray shows 3
/// pieces at a time; tray refills when all 3 are placed").
const int traySize = 3;

/// Points awarded for every grid cell a placed piece fills (BUILD_PROMPTS
/// 1.4). Tunable here, never inlined in logic or widgets (AI_RULES #5).
const int pointsPerCellFilled = 1;

/// Bonus points awarded for every row or column cleared by a placement
/// (BUILD_PROMPTS 1.4). Rows and columns count equally as "lines". Tunable
/// here, never inlined in logic or widgets (AI_RULES #5).
const int bonusPerLineCleared = 10;

/// Probability, per generated tray, that one of its [traySize] pieces is the
/// special "line/column clear" piece (PRD 5.2: "appears roughly every 5–8
/// piece-tray refreshes" — 1/6 sits mid-range). Tunable here, never inlined
/// in logic (AI_RULES #5).
//
// The SCREAMING_SNAKE_CASE name is mandated verbatim by BUILD_PROMPTS 1.3
// ("a tunable constant SPECIAL_PIECE_SPAWN_RATE"), so the naming lint is
// intentionally waived for this one constant.
// ignore: constant_identifier_names
const double SPECIAL_PIECE_SPAWN_RATE = 1 / 6;

/// Number of sub-stages per civilization (PRD 5.3: "Every civilization has
/// 30 sub-stages"; 8 civilizations x 30 stages = 240 total). Stage unlock
/// logic in the progress controller reads this instead of inlining 30.
const int stagesPerCivilization = 30;

/// Generic landmark reference used by generated pieces until the
/// civilization content phase assigns real landmark ids (BUILD_PROMPTS 1.3).
const String placeholderLandmarkId = 'placeholder';
