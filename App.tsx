import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, Dimensions, Platform } from 'react-native';
import { Camera } from 'expo-camera';
import * as tf from '@tensorflow/tfjs';
import { cameraWithTensors } from '@tensorflow/tfjs-react-native';

export default function App() {
  // Camera permissions
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);

  //  Tensor Camera
  const TensorCamera = cameraWithTensors(Camera);

  // Screen Ratio
  const { height, width } = Dimensions.get('window');
  
  // Camera dimension
  const cameraWidth = width;
  const cameraHeight = (4 / 3) * width;

  // Tensorflow and Permissions
  // check model state here (not available yet)
  const [frameworkReady, setFrameworkReady] = useState(false);

  // Performance hacks (Platform dependent)
  const textureDims = Platform.OS === "ios"? { width: 1080, height: 1920 } : { width: 1600, height: 1200 };
  const tensorDims = { width: 152, height: 200 };

  useEffect(() => {
    if(!frameworkReady) {
      (async () => {
        // Check camera permission
        const { status } = await Camera.requestPermissionsAsync();
        setHasPermission(status === 'granted');

        // Wait for the Tensorflow API to be ready before any TF operation
        await tf.ready();

        // Load the model and save it in state


        // Ready
        setFrameworkReady(true);
      })();
    }
  }, []);

  const handleCameraStream = (imageAsTensors: any) => {
    const loop = async () => {
      const nextImageTensor = await imageAsTensors.next().value;
      //await getPrediction(nextImageTensor);
      //requestAnimationFrameId = requestAnimationFrame(loop);
      requestAnimationFrame(loop);
    };
    //if(!predictionFound) loop();
    loop();
  }

  if (hasPermission === null) {
    return <View />;
  }
  if (hasPermission === false) {
    return <Text>No access to camera</Text>;
  }
  return (
    <View style={styles.container}>
      <TensorCamera
        // Standard Camera props
        style={[styles.camera, {width: cameraWidth, height: cameraHeight}]}
        type={Camera.Constants.Type.back}
        // Tensor related props
        cameraTextureHeight={textureDims.height}
        cameraTextureWidth={textureDims.width}
        resizeHeight={tensorDims.height}
        resizeWidth={tensorDims.width}
        resizeDepth={3}
        onReady={(imageAsTensors) => handleCameraStream(imageAsTensors)}
        autorender={true}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    backgroundColor: 'transparent',
    flexDirection: 'row'
  },
  camera: {
    flex: 1,
    marginTop: 50
  },
});