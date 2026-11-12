import { RULE_VERSION } from '@hype2gether/scoring';
import { BRAND_NAME } from '@hype2gether/shared';
import { StyleSheet, Text, View } from 'react-native';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{BRAND_NAME}</Text>
      <Text style={styles.subtitle}>Scoring rules v{RULE_VERSION}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
  },
  subtitle: {
    fontSize: 16,
    opacity: 0.6,
  },
});
