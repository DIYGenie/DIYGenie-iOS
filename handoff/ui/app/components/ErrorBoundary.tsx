import React from 'react';
import { View, Text } from 'react-native';

export class ErrorBoundary extends React.Component<any, {error: any}> {
  constructor(props:any){ super(props); this.state = { error: null }; }
  static getDerivedStateFromError(error:any){ return { error }; }
  componentDidCatch(error:any, info:any){ console.error('[crash] boundary', { error: String(error), info }); }
  render(){
    if (this.state.error){
      return (
        <View style={{ flex:1, padding:16, alignItems:'center', justifyContent:'center' }}>
          <Text style={{ fontSize:16, fontWeight:'700' }}>Something went wrong</Text>
          <Text style={{ marginTop:8, opacity:0.7 }}>Please restart the app. If this persists, contact support.</Text>
        </View>
      );
    }
    return this.props.children;
  }
}
