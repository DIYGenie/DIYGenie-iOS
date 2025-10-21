import React from 'react';
import { Modal, View, Text, TouchableOpacity } from 'react-native';

type Props = {
  visible: boolean;
  tip: string | null;
  onReplace: () => void;
  onAppend: () => void;
  onClose: () => void;
};

export default function PromptApplyModal({ visible, tip, onReplace, onAppend, onClose }: Props) {
  return (
    <Modal transparent visible={visible} animationType="fade" onRequestClose={onClose}>
      <View style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.35)', justifyContent: 'flex-end' }}>
        <View style={{ backgroundColor: '#fff', padding: 16, borderTopLeftRadius: 16, borderTopRightRadius: 16 }}>
          <Text style={{ fontWeight: '700', fontSize: 16, marginBottom: 8 }}>Use this suggestion?</Text>
          <Text style={{ opacity: 0.8, marginBottom: 16 }}>{tip}</Text>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
            <TouchableOpacity onPress={onReplace} style={{ padding: 12 }}>
              <Text style={{ fontWeight: '600' }}>Replace</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={onAppend} style={{ padding: 12 }}>
              <Text style={{ fontWeight: '600' }}>Append</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={onClose} style={{ padding: 12 }}>
              <Text>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}
