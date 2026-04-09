import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/services/services.dart';

class TranslationCubit extends Cubit<TranslationState> with Loggable {
  TranslationCubit({
    TranslationService? translationService,
  })  : _translationService =
            translationService ?? locator.get<TranslationService>(),
        super(const TranslationState());

  final TranslationService _translationService;

  Future<void> toggle({
    required String text,
  }) async {
    if (state.translatedText != null) {
      emit(
        state.copyWith(
          isVisible: !state.isVisible,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: Status.inProgress,
        isVisible: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final String translatedText =
          await _translationService.translate(text: text);
      emit(
        state.copyWith(
          status: Status.success,
          translatedText: translatedText,
          isVisible: true,
          clearErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: Status.failure,
          isVisible: false,
          errorMessage: error.message ?? 'Translation failed.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: Status.failure,
          isVisible: false,
          errorMessage: 'Translation failed.',
        ),
      );
    }
  }

  @override
  String get logIdentifier => 'TranslationCubit';
}

class TranslationState extends Equatable {
  const TranslationState({
    this.status = Status.idle,
    this.translatedText,
    this.errorMessage,
    this.isVisible = false,
  });

  final Status status;
  final String? translatedText;
  final String? errorMessage;
  final bool isVisible;

  TranslationState copyWith({
    Status? status,
    String? translatedText,
    String? errorMessage,
    bool? isVisible,
    bool clearErrorMessage = false,
  }) {
    return TranslationState(
      status: status ?? this.status,
      translatedText: translatedText ?? this.translatedText,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        translatedText,
        errorMessage,
        isVisible,
      ];
}
