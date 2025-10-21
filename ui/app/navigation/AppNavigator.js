import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import AuthGate from '../providers/AuthGate';
import WelcomeScreen from '../screens/WelcomeScreen';
import RootTabs from './RootTabs';
import HowItWorks from '../screens/HowItWorks';
import NewProject from '../screens/NewProject';
// Force the minimal JS component (upload-only)
import NewProjectMedia from '../screens/NewProjectMedia.js';
import ScanScreen from '../screens/ScanScreen';
// import ProjectPreview from '../screens/ProjectPreview'; // Legacy debug screen - removed
import ProjectDetailScreen from '../screens/ProjectDetailScreen';
import PlanScreen from '../screens/PlanScreen';
import PlanTabsScreen from '../screens/PlanTabsScreen';
import OpenPlanScreen from '../screens/OpenPlanScreen';
import AuthScreen from '../screens/AuthScreen';
import Diagnostics from '../screens/Diagnostics';

const Stack = createStackNavigator();

export default function AppNavigator() {
  return (
    <AuthGate>
      <Stack.Navigator
        screenOptions={{
          headerShown: false,
        }}
        initialRouteName="Welcome"
      >
        <Stack.Screen name="Welcome" component={WelcomeScreen} />
        <Stack.Screen name="Main" component={RootTabs} />
        <Stack.Screen name="HowItWorks" component={HowItWorks} />
        <Stack.Screen name="NewProject" component={NewProject} />
        <Stack.Screen name="NewProjectMedia" component={NewProjectMedia} />
        <Stack.Screen 
          name="Scan" 
          component={ScanScreen} 
          options={{ headerShown: false, presentation: 'modal' }} 
        />
        <Stack.Screen 
          name="Auth" 
          component={AuthScreen} 
          options={{ headerShown: true, title: 'Sign in' }} 
        />
        {/* Legacy debug screen - removed in favor of real preview flow */}
        {/* <Stack.Screen name="ProjectPreview" component={ProjectPreview} /> */}
        <Stack.Screen name="Project" component={ProjectDetailScreen} />
        <Stack.Screen name="Plan" component={PlanScreen} />
        <Stack.Screen name="PlanTabs" component={PlanTabsScreen} />
        <Stack.Screen name="OpenPlan" component={OpenPlanScreen} options={{ headerShown: false }} />
        <Stack.Screen name="Diagnostics" component={Diagnostics} options={{ headerShown: true, headerTitle: 'Diagnostics', presentation: 'card' }} />
      </Stack.Navigator>
    </AuthGate>
  );
}