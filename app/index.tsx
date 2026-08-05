// app/index.tsx
import React, { useEffect } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { useAppState } from '../src/context/AppStateContext';

export default function Index() {
  const { state, isLoading } = useAppState();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading) {
      router.replace('/splash');
    }
  }, [isLoading]);

  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" color="#D88A2D" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F4EF',
    justifyContent: 'center',
    alignItems: 'center',
  },
});
