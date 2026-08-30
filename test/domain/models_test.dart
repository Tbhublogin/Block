// Pure-Dart unit tests for the domain models (no Flutter imports here, so
// the models provably carry no widget dependencies).
import 'package:block_civilizations/domain/models/board_cell.dart';
import 'package:block_civilizations/domain/models/civilization.dart';
import 'package:block_civilizations/domain/models/game_result.dart';
import 'package:block_civilizations/domain/models/landmark_info.dart';
import 'package:block_civilizations/domain/models/piece.dart';
import 'package:block_civilizations/domain/models/stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardCell', () {
    test('empty cell has no landmark and is empty', () {
      const cell = BoardCell.empty();

      expect(cell.isEmpty, isTrue);
      expect(cell.isFilled, isFalse);
      expect(cell.landmarkId, isNull);
    });

    test('filled cell keeps its landmarkId', () {
      const cell = BoardCell.filled('ziggurat_of_ur');

      expect(cell.isEmpty, isFalse);
      expect(cell.isFilled, isTrue);
      expect(cell.landmarkId, 'ziggurat_of_ur');
    });

    test('value equality', () {
      expect(const BoardCell.empty(), const BoardCell.empty());
      expect(
        const BoardCell.filled('ishtar_gate'),
        const BoardCell.filled('ishtar_gate'),
      );
      expect(
        const BoardCell.filled('ishtar_gate'),
        isNot(const BoardCell.filled('lamassu')),
      );
      expect(
        const BoardCell.filled('ishtar_gate'),
        isNot(const BoardCell.empty()),
      );
    });
  });

  group('Piece', () {
    test('reports bounding-box geometry and filled cell count', () {
      const piece = Piece(
        id: 'l_shape',
        shapeMatrix: [
          [true, false],
          [true, true],
        ],
        landmarkId: 'placeholder',
      );

      expect(piece.rows, 2);
      expect(piece.cols, 2);
      expect(piece.filledCellCount, 3);
      expect(piece.isSpecial, isFalse);
    });

    test('supports 5x5 shapes', () {
      final piece = Piece(
        id: 'big_i',
        shapeMatrix: List.generate(5, (_) => [true, true, true, true, true]),
        landmarkId: 'placeholder',
      );

      expect(piece.rows, 5);
      expect(piece.cols, 5);
      expect(piece.filledCellCount, 25);
    });

    test('special constructor produces a 1x1 [[true]] special piece', () {
      const piece = Piece.special(id: 'special', landmarkId: 'placeholder');

      expect(piece.isSpecial, isTrue);
      expect(piece.shapeMatrix, [
        [true],
      ]);
      expect(piece.rows, 1);
      expect(piece.cols, 1);
      expect(piece.filledCellCount, 1);
    });

    test('value equality uses deep matrix comparison', () {
      const matrix = [
        [true, true],
      ];
      const a = Piece(id: 'duo', shapeMatrix: matrix, landmarkId: 'x');
      const b = Piece(id: 'duo', shapeMatrix: matrix, landmarkId: 'x');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const Piece(
            id: 'duo',
            shapeMatrix: [
              [true, false],
            ],
            landmarkId: 'x',
          ),
        ),
      );
      expect(
        a,
        isNot(const Piece(id: 'other', shapeMatrix: matrix, landmarkId: 'x')),
      );
    });

    test('rejects isSpecial on the normal constructor', () {
      const malformed = [
        [true, true],
      ];

      expect(
        () => Piece(
          id: 'bad_special',
          shapeMatrix: malformed,
          isSpecial: true,
          landmarkId: 'x',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('GameResult', () {
    test('isWin/isLose reflect the outcome', () {
      const win = GameResult(
        stageId: 'iraq_01',
        outcome: GameOutcome.win,
        score: 500,
        targetScore: 500,
      );
      const lose = GameResult(
        stageId: 'iraq_01',
        outcome: GameOutcome.lose,
        score: 200,
        targetScore: 500,
      );

      expect(win.isWin, isTrue);
      expect(win.isLose, isFalse);
      expect(lose.isWin, isFalse);
      expect(lose.isLose, isTrue);
    });

    test('value equality', () {
      const result = GameResult(
        stageId: 'iraq_02',
        outcome: GameOutcome.lose,
        score: 300,
        targetScore: 800,
      );

      expect(
        result,
        const GameResult(
          stageId: 'iraq_02',
          outcome: GameOutcome.lose,
          score: 300,
          targetScore: 800,
        ),
      );
      expect(result, isNot(result.copyWith(outcome: GameOutcome.win)));
    });
  });

  group('Civilization', () {
    test('emblemAsset is optional and defaults to null', () {
      const civ = Civilization(
        id: 'iraq',
        nameKey: 'civIraqName',
        themeColorHex: '#C9A227',
        stages: [],
      );

      expect(civ.emblemAsset, isNull);
    });

    test('value equality covers every field including stage lists', () {
      const stages = [
        Stage(id: 'iraq_01', orderIndex: 1, targetScore: 1000),
        Stage(id: 'iraq_02', orderIndex: 2, targetScore: 2000),
      ];
      const civ = Civilization(
        id: 'iraq',
        nameKey: 'civIraqName',
        emblemAsset: null,
        themeColorHex: '#C9A227',
        stages: stages,
      );

      expect(
        civ,
        const Civilization(
          id: 'iraq',
          nameKey: 'civIraqName',
          emblemAsset: null,
          themeColorHex: '#C9A227',
          stages: stages,
        ),
      );
      // Different stage content (same length) must break equality.
      expect(
        civ,
        isNot(
          const Civilization(
            id: 'iraq',
            nameKey: 'civIraqName',
            themeColorHex: '#C9A227',
            stages: [
              Stage(id: 'iraq_01', orderIndex: 1, targetScore: 1000),
              Stage(id: 'iraq_02', orderIndex: 2, targetScore: 9999),
            ],
          ),
        ),
      );
      expect(civ, isNot(civ.copyWith(emblemAsset: 'assets/emblem.png')));
    });
  });

  group('LandmarkInfo', () {
    test('value equality', () {
      const landmark = LandmarkInfo(
        id: 'ziggurat_of_ur',
        civilizationId: 'iraq',
        nameKey: 'landmarkZigguratOfUrName',
        historicalFactKey: 'landmarkZigguratOfUrFact',
        imageAsset: 'assets/civilizations/iraq/ziggurat_of_ur.png',
      );

      expect(
        landmark,
        const LandmarkInfo(
          id: 'ziggurat_of_ur',
          civilizationId: 'iraq',
          nameKey: 'landmarkZigguratOfUrName',
          historicalFactKey: 'landmarkZigguratOfUrFact',
          imageAsset: 'assets/civilizations/iraq/ziggurat_of_ur.png',
        ),
      );
      expect(landmark, isNot(landmark.copyWith(id: 'ishtar_gate')));
    });
  });
}

extension on Civilization {
  Civilization copyWith({String? emblemAsset}) => Civilization(
    id: id,
    nameKey: nameKey,
    emblemAsset: emblemAsset ?? this.emblemAsset,
    themeColorHex: themeColorHex,
    stages: stages,
  );
}

extension on LandmarkInfo {
  LandmarkInfo copyWith({String? id}) => LandmarkInfo(
    id: id ?? this.id,
    civilizationId: civilizationId,
    nameKey: nameKey,
    historicalFactKey: historicalFactKey,
    imageAsset: imageAsset,
  );
}

extension on GameResult {
  GameResult copyWith({GameOutcome? outcome}) => GameResult(
    stageId: stageId,
    outcome: outcome ?? this.outcome,
    score: score,
    targetScore: targetScore,
  );
}
