// src/components/CravingPauseModal.tsx
import React, { useState, useEffect, useRef } from 'react';
import { Modal, View, Text, StyleSheet, Pressable, Animated, Easing } from 'react-native';
import { ThemeColors } from '../constants/theme';
import { useAppState } from '../context/AppStateContext';
import { HapticService } from '../services/notification';

interface CravingPauseModalProps {
  visible: boolean;
  onClose: () => void;
}

export const CravingPauseModal: React.FC<CravingPauseModalProps> = ({ visible, onClose }) => {
  const { state } = useAppState();
  const [currentStep, setCurrentStep] = useState(0);
  const [breathState, setBreathState] = useState<'inhale' | 'exhale'>('inhale');

  const scaleAnim = useRef(new Animated.Value(1)).current;

  const isDark = state.displaySettings.isDarkMode;
  const colors = isDark ? ThemeColors.dark : ThemeColors.light;

  // Breathing Loop Animation for Step 1 (4s Inhale, 4s Exhale)
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    if (visible && currentStep === 0) {
      const animateBreath = () => {
        setBreathState('inhale');
        Animated.timing(scaleAnim, {
          toValue: 1.4,
          duration: 4000,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }).start(() => {
          setBreathState('exhale');
          Animated.timing(scaleAnim, {
            toValue: 1.0,
            duration: 4000,
            easing: Easing.inOut(Easing.ease),
            useNativeDriver: true,
          }).start(() => {
            animateBreath();
          });
        });
      };

      animateBreath();
    } else {
      scaleAnim.setValue(1);
    }
    return () => {
      scaleAnim.stopAnimation();
    };
  }, [visible, currentStep]);

  const steps = [
    {
      stepNumber: '1단계',
      title: '4초 깊은 호흡 가이드',
      instruction: breathState === 'inhale' ? '천천히 4초간 공기를 마셔보세요...' : '천천히 4초간 공기를 내쉬어보세요...',
      icon: '🌬️',
    },
    {
      stepNumber: '2단계',
      title: '미지근한 물 한 잔',
      instruction: '물 한 잔을 입에 모금고 천천히 넘기며 입안의 감각에 집중해 보세요.',
      icon: '💧',
    },
    {
      stepNumber: '3단계',
      title: '자극 공간 이동',
      instruction: '현재 서 있거나 앉아 있는 장소에서 3m 이상 떨어진 곳으로 자리를 이동해 보세요.',
      icon: '🚶',
    },
  ];

  const handleNext = () => {
    HapticService.lightImpact();
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      handleClose();
    }
  };

  const handleClose = () => {
    setCurrentStep(0);
    onClose();
  };

  const activeStep = steps[currentStep];

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={handleClose}>
      <View style={styles.overlay}>
        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text style={[styles.badge, { backgroundColor: colors.accentLight, color: colors.accent }]}>
            3분 대기 루틴 (Craving Pause)
          </Text>

          {/* Interactive Breathing Visualizer for Step 1 */}
          {currentStep === 0 ? (
            <View style={styles.breathContainer}>
              <Animated.View
                style={[
                  styles.breathCircle,
                  {
                    backgroundColor: colors.accentLight,
                    borderColor: colors.accent,
                    transform: [{ scale: scaleAnim }],
                  },
                ]}
              />
              <Text style={styles.icon}>{activeStep.icon}</Text>
            </View>
          ) : (
            <Text style={styles.icon}>{activeStep.icon}</Text>
          )}

          <Text style={[styles.stepLabel, { color: colors.accent }]}>{activeStep.stepNumber}</Text>
          <Text style={[styles.title, { color: colors.textPrimary }]}>{activeStep.title}</Text>
          <Text style={[styles.instruction, { color: colors.textSecondary }]}>{activeStep.instruction}</Text>

          {/* Dots Indicator */}
          <View style={styles.dotsRow}>
            {steps.map((_, idx) => (
              <View
                key={idx}
                style={[
                  styles.dot,
                  {
                    backgroundColor: idx === currentStep ? colors.accent : colors.border,
                    width: idx === currentStep ? 16 : 8,
                  },
                ]}
              />
            ))}
          </View>

          {/* Actions */}
          <View style={styles.buttonRow}>
            <Pressable
              style={[styles.closeBtn, { backgroundColor: colors.surfaceSecondary }]}
              onPress={handleClose}
            >
              <Text style={[styles.closeBtnText, { color: colors.textSecondary }]}>종료</Text>
            </Pressable>
            <Pressable
              style={[styles.nextBtn, { backgroundColor: colors.accent }]}
              onPress={handleNext}
            >
              <Text style={styles.nextBtnText}>
                {currentStep === steps.length - 1 ? '루틴 완료' : '다음 단계'}
              </Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  card: {
    width: '100%',
    borderRadius: 24,
    borderWidth: 1,
    padding: 24,
    alignItems: 'center',
  },
  badge: {
    fontSize: 11,
    fontWeight: '700',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 10,
    overflow: 'hidden',
    marginBottom: 16,
  },
  breathContainer: {
    width: 100,
    height: 100,
    justifyContent: 'center',
    alignItems: 'center',
    marginVertical: 8,
  },
  breathCircle: {
    position: 'absolute',
    width: 70,
    height: 70,
    borderRadius: 35,
    borderWidth: 2,
    opacity: 0.6,
  },
  icon: {
    fontSize: 40,
    marginVertical: 8,
  },
  stepLabel: {
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 4,
  },
  title: {
    fontSize: 20,
    fontWeight: '800',
    marginBottom: 8,
    textAlign: 'center',
  },
  instruction: {
    fontSize: 14,
    lineHeight: 21,
    textAlign: 'center',
    marginBottom: 20,
  },
  dotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 24,
  },
  dot: {
    height: 8,
    borderRadius: 4,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
    width: '100%',
  },
  closeBtn: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  closeBtnText: {
    fontSize: 14,
    fontWeight: '600',
  },
  nextBtn: {
    flex: 2,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  nextBtnText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#FFFFFF',
  },
});
