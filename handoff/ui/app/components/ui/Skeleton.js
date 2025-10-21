import React, { useEffect, useRef } from 'react';
import { View, Animated, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

export default function Skeleton({ 
  width = '100%', 
  height = 20, 
  borderRadius = 12,
  style 
}) {
  const shimmerAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const animation = Animated.loop(
      Animated.timing(shimmerAnim, {
        toValue: 1,
        duration: 1400,
        useNativeDriver: true,
      })
    );
    animation.start();
    return () => animation.stop();
  }, []);

  const translateX = shimmerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [-300, 300],
  });

  return (
    <View 
      style={[
        styles.container, 
        { width, height, borderRadius },
        style
      ]}
    >
      <Animated.View
        style={[
          styles.shimmerContainer,
          { transform: [{ translateX }] }
        ]}
      >
        <View style={styles.gradientWrapper}>
          <LinearGradient
            colors={['#ECEBF6', '#FFFFFF4D', '#ECEBF6']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={styles.gradient}
          />
        </View>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#ECEBF6',
    overflow: 'hidden',
  },
  shimmerContainer: {
    width: '100%',
    height: '100%',
  },
  gradientWrapper: {
    width: 300,
    height: '100%',
  },
  gradient: {
    width: '100%',
    height: '100%',
  },
});
