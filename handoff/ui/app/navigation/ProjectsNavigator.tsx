import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import ProjectsScreen from '../screens/ProjectsScreen';
import OpenPlanScreen from '../screens/OpenPlanScreen';
import ProjectDetails from '../screens/ProjectDetails';
import DetailedInstructions from '../screens/DetailedInstructions';
import { PLAN_SCREEN, PROJECTS_LIST_SCREEN } from './routeNames';

export type ProjectsStackParamList = {
  ProjectsList: undefined;
  OpenPlan: { id: string };
  ProjectDetails: { id: string; imageUrl?: string | null };
  DetailedInstructions: { id: string };
};

const Stack = createNativeStackNavigator<ProjectsStackParamList>();

export default function ProjectsNavigator() {
  return (
    <Stack.Navigator 
      screenOptions={{ headerShown: false }}
      id={undefined}
    >
      <Stack.Screen
        name={PROJECTS_LIST_SCREEN}
        component={ProjectsScreen}
      />
      <Stack.Screen
        name={PLAN_SCREEN}
        component={OpenPlanScreen}
      />
      <Stack.Screen
        name="ProjectDetails"
        component={ProjectDetails}
        options={{ headerShown: true, title: 'Project' }}
      />
      <Stack.Screen
        name="DetailedInstructions"
        component={DetailedInstructions}
        options={{ headerShown: true, title: 'Project Plan' }}
      />
    </Stack.Navigator>
  );
}
