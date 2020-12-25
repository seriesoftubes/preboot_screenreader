import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, Dimensions, Platform } from 'react-native';
import { Camera } from 'expo-camera';
import * as tf from '@tensorflow/tfjs';
import { bundleResourceIO, cameraWithTensors } from '@tensorflow/tfjs-react-native';
import { GraphModel, Tensor } from '@tensorflow/tfjs';

// Disable logs on EXPO client!
import { LogBox } from 'react-native';
LogBox.ignoreAllLogs();//Ignore all log notifications
console.log('STARTING');

export default function App() {
  // Camera permissions
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);

  //  Tensor Camera
  const TensorCamera = cameraWithTensors(Camera);
  let requestAnimationFrameID = 0;

  // Screen Ratio
  const { height, width } = Dimensions.get('window');
  
  // Camera dimension
  const cameraWidth = width;
  const cameraHeight = (4 / 3) * width;

  // Tensorflow and Permissions
  // Check model state
  const [model, setModel] = useState<GraphModel | null>(null);
  const [frameworkReady, setFrameworkReady] = useState(false);

  // Performance hacks (Platform dependent)
  const textureDims = Platform.OS === "ios"? { width: 1080, height: 1920 } : { width: 1600, height: 1200 };
  const tensorDims = { width: 180, height: 180 };

  const [prediction, setPrediction] = useState<String | undefined>('');

  // -----------------------------
  // Initialize
  useEffect(() => {
    if (!frameworkReady) {
      (async () => {
        // Check camera permission
        const { status } = await Camera.requestPermissionsAsync();
        setHasPermission(status === 'granted');

        // Wait for the Tensorflow API to be ready before any TF operation
        await tf.ready();

        console.log('LOADING MODEL');
        
        // Load the model and save it in state
        setModel(await loadModel());
        console.log('MODEL LOADED');
        

        // Ready
        setFrameworkReady(true);
        console.log('FRAMEWORK READY');
        
      })();
    }
  }, []);

  useEffect(() => {
    if (requestAnimationFrameID) {
      cancelAnimationFrame(requestAnimationFrameID);
    }
  }, []);

  const loadModel = async () => {
    const modelJSON = await require('./assets/model/model.json');
    const modelWeights = await require('./assets/model/group1-shard.bin');
    const model = await tf.loadGraphModel(bundleResourceIO(modelJSON, modelWeights));
    
    return model;
  }

  const getPrediction = async (tensor: Tensor) => {
    if (!tensor) { return '' }
    if (!model) { return '' }

    // Get probabilities
    const output = model.predict(tensor.expandDims(0).toFloat()) as Tensor;
    console.log(output.dataSync());
    
    const predictions = Array.from(output.argMax(1).dataSync())
    console.log(predictions);

    var className = '';

    if (predictions[0] == 1)
    {
      className = 'BIOS_SCREEN'
    }
    else if (predictions[0] == 2)
    {
      className = 'BOOT_SCREEN'
    }
    else
    {
      className = 'NONE'
    }
    console.log(className);
    
    return className;
  }

  const handleCameraStream = (imageAsTensors: IterableIterator<tf.Tensor3D>) => {
    const loop = async () => {
      const nextImageTensor = await imageAsTensors.next().value;
      setPrediction(await getPrediction(nextImageTensor));
      
      requestAnimationFrame(loop);
    };
    loop();
  }

  if (hasPermission === null) {
    return <View />;
  }
  if (hasPermission === false) {
    return <Text>No access to camera</Text>;
  }
  if (model === null) {
    return <Text>Model not loaded</Text>;
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
      
      <Text style={styles.text}>{prediction}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'transparent'
  },
  camera: {
    marginTop: 50
  },
  body: {
    justifyContent: 'center',
    marginBottom: 50
  },
  text: {
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    color: '#000000'
  }
});