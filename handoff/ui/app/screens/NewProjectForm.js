import React from 'react';

// DEPRECATED: This screen is retired. Use NewProject.tsx instead.
export default function NewProjectForm({ navigation }) {
  console.warn('NewProjectForm is deprecated; using NewProject.tsx.');
  
  // Auto-redirect to the new screen if somehow reached
  React.useEffect(() => {
    if (navigation) {
      navigation.replace('NewProject');
    }
  }, [navigation]);
  
  return null;
}
