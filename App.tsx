import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, Dimensions, Platform } from 'react-native';
import { Camera } from 'expo-camera';
import * as tf from '@tensorflow/tfjs';
import { bundleResourceIO, cameraWithTensors } from '@tensorflow/tfjs-react-native';

// Disable logs on EXPO client!
import { LogBox } from 'react-native';
LogBox.ignoreAllLogs();//Ignore all log notifications
console.log('STARTING');

export default function App() {
  // Camera permissions
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);

  //  Tensor Camera
  const TensorCamera = cameraWithTensors(Camera);
  let requestAnimationFrameId = 0;

  // Screen Ratio
  const { height, width } = Dimensions.get('window');
  
  // Camera dimension
  const cameraWidth = width;
  const cameraHeight = (4 / 3) * width;

  // Check model state
  const [model, setModel] = useState<tf.GraphModel | null>(null);
  const [frameworkReady, setFrameworkReady] = useState(false);

  // Performance hacks (Platform dependent)
  const textureDims = Platform.OS === "ios"? { width: 1080, height: 1920 } : { width: 1600, height: 1200 };
  const tensorDims = { width: 180, height: 180 };

  // Prediction
  const [prediction, setPrediction] = useState<String | undefined>('');

  // Import model.json and model weights
  const modelJson = require('./assets/model/model.json');
  const modelWeights1: number = require('./assets/model/group1-shard1of4.bin');
  const modelWeights2: number = require('./assets/model/group1-shard2of4.bin');
  const modelWeights3: number = require('./assets/model/group1-shard3of4.bin');
  const modelWeights4: number = require('./assets/model/group1-shard4of4.bin');

  // Screen class names 
  const classNames = ['BIOS SCREEN', 'BOOT SCREEN'];

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

  //--------------------------
  // Run onUnmount routine
  // for cancelling animation 
  // (if running) to avoid leaks
  //--------------------------
  useEffect(() => {
    return () => {
      cancelAnimationFrame(requestAnimationFrameId);
    };
  }, [requestAnimationFrameId]);

  const loadModel = async () => {
    
    const model = await tf.loadGraphModel(bundleResourceIO(
      modelJson, [modelWeights1, modelWeights2, modelWeights3, modelWeights4]));
    
    return model;
  }

  const getPrediction = async (tensor: tf.Tensor3D) => {
    if (!tensor) { return '' }
    if (!model) { return '' }

    var className = '';

    // Get prediction
    const input = tensor.expandDims(0).toFloat();
    const predictions = model.predict(input) as tf.Tensor;
    const scores = tf.softmax(predictions).dataSync();

    // Check if probability is more than 90%
    const probability = Number(tf.max(scores).dataSync());
    if (probability > 0.9) {
      className = classNames[Number(tf.argMax(scores).dataSync())];
      console.log(className);
      console.log('CONFIDENCE: ', 100 * Number(tf.max(scores).dataSync()));
    }
    else {
      className = 'SCREEN NOT DETECTED'
    }

    cancelAnimationFrame(requestAnimationFrameId);
    
    return className;
  }

  const handleCameraStream = (imageAsTensors: IterableIterator<tf.Tensor3D>) => {
    const loop = async () => {
      const nextImageTensor = await imageAsTensors.next().value;
      setPrediction(await getPrediction(nextImageTensor));
      requestAnimationFrameId = requestAnimationFrame(loop);
    };
    setTimeout(() => {
      loop();
    }, 5000);
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