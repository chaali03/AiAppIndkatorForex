#!/usr/bin/env python3
"""
ADVANCED CRYPTO MODEL TRAINER - WORLD CLASS ACCURACY
Train AI models with simulated trading data yang mirip dengan real market data
untuk mencapai akurasi setingkat TradingView Professional.
"""

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import accuracy_score, classification_report
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

class AdvancedCryptoTrainer:
    def __init__(self):
        """Initialize the advanced crypto trainer"""
        self.models = {}
        self.scalers = {}
        self.accuracy_threshold = 0.95  # Target 95% accuracy like TradingView
        
    def generate_realistic_crypto_data(self, num_samples=50000):
        """Generate realistic cryptocurrency trading data"""
        print("🎯 Generating realistic crypto trading data...")
        
        # Base price untuk cryptocurrency (Bitcoin-like)
        base_price = 50000
        volatility = 0.02  # 2% volatility per candle
        
        data = []
        current_price = base_price
        
        # Generate realistic OHLCV data
        for i in range(num_samples):
            # Random walk dengan trend
            trend_factor = np.random.normal(0, 0.001)  # Small trend bias
            price_change = np.random.normal(trend_factor, volatility)
            
            # Calculate OHLCV
            open_price = current_price
            close_price = open_price * (1 + price_change)
            
            # High and Low dengan realistic spread
            high_low_range = abs(close_price - open_price) * np.random.uniform(1.2, 3.0)
            high_price = max(open_price, close_price) + np.random.uniform(0, high_low_range * 0.6)
            low_price = min(open_price, close_price) - np.random.uniform(0, high_low_range * 0.6)
            
            volume = np.random.lognormal(10, 1)  # Realistic volume distribution
            
            data.append({
                'timestamp': i,
                'open': open_price,
                'high': high_price,
                'low': low_price,
                'close': close_price,
                'volume': volume
            })
            
            current_price = close_price
            
        return pd.DataFrame(data)
    
    def calculate_technical_indicators(self, df):
        """Calculate comprehensive technical indicators like TradingView"""
        print("📊 Calculating TradingView-level technical indicators...")
        
        # Price-based indicators
        df['sma_20'] = df['close'].rolling(window=20).mean()
        df['sma_50'] = df['close'].rolling(window=50).mean()
        df['ema_12'] = df['close'].ewm(span=12).mean()
        df['ema_26'] = df['close'].ewm(span=26).mean()
        
        # MACD
        df['macd'] = df['ema_12'] - df['ema_26']
        df['macd_signal'] = df['macd'].ewm(span=9).mean()
        df['macd_histogram'] = df['macd'] - df['macd_signal']
        
        # RSI
        delta = df['close'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
        rs = gain / loss
        df['rsi'] = 100 - (100 / (1 + rs))
        
        # Bollinger Bands
        df['bb_middle'] = df['close'].rolling(window=20).mean()
        bb_std = df['close'].rolling(window=20).std()
        df['bb_upper'] = df['bb_middle'] + (bb_std * 2)
        df['bb_lower'] = df['bb_middle'] - (bb_std * 2)
        df['bb_position'] = (df['close'] - df['bb_lower']) / (df['bb_upper'] - df['bb_lower'])
        
        # Stochastic
        low_14 = df['low'].rolling(window=14).min()
        high_14 = df['high'].rolling(window=14).max()
        df['stoch_k'] = 100 * ((df['close'] - low_14) / (high_14 - low_14))
        df['stoch_d'] = df['stoch_k'].rolling(window=3).mean()
        
        # Williams %R
        df['williams_r'] = -100 * ((high_14 - df['close']) / (high_14 - low_14))
        
        # CCI (Commodity Channel Index)
        tp = (df['high'] + df['low'] + df['close']) / 3
        sma_tp = tp.rolling(window=20).mean()
        mad = tp.rolling(window=20).apply(lambda x: np.mean(np.abs(x - x.mean())))
        df['cci'] = (tp - sma_tp) / (0.015 * mad)
        
        # ADX (Average Directional Index) - simplified
        high_diff = df['high'].diff()
        low_diff = df['low'].diff()
        plus_dm = high_diff.where((high_diff > low_diff) & (high_diff > 0), 0)
        minus_dm = low_diff.where((low_diff > high_diff) & (low_diff > 0), 0)
        
        tr = np.maximum(df['high'] - df['low'], 
             np.maximum(abs(df['high'] - df['close'].shift(1)),
                       abs(df['low'] - df['close'].shift(1))))
        
        plus_di = 100 * (plus_dm.rolling(window=14).mean() / tr.rolling(window=14).mean())
        minus_di = 100 * (minus_dm.rolling(window=14).mean() / tr.rolling(window=14).mean())
        
        dx = 100 * abs(plus_di - minus_di) / (plus_di + minus_di)
        df['adx'] = dx.rolling(window=14).mean()
        
        # Volume indicators
        df['volume_sma'] = df['volume'].rolling(window=20).mean()
        df['volume_ratio'] = df['volume'] / df['volume_sma']
        
        # Price momentum
        df['momentum'] = df['close'].pct_change(periods=10)
        df['roc'] = ((df['close'] - df['close'].shift(12)) / df['close'].shift(12)) * 100
        
        return df
    
    def create_pattern_features(self, df):
        """Create candlestick pattern features"""
        print("🕯️ Creating candlestick pattern features...")
        
        # Basic candle properties
        df['body'] = abs(df['close'] - df['open'])
        df['upper_shadow'] = df['high'] - np.maximum(df['open'], df['close'])
        df['lower_shadow'] = np.minimum(df['open'], df['close']) - df['low']
        df['total_range'] = df['high'] - df['low']
        
        # Pattern indicators
        df['is_bullish'] = (df['close'] > df['open']).astype(int)
        df['is_bearish'] = (df['close'] < df['open']).astype(int)
        df['is_doji'] = (df['body'] < df['total_range'] * 0.1).astype(int)
        
        # Hammer and Shooting Star patterns
        df['is_hammer'] = ((df['lower_shadow'] > df['body'] * 2) & 
                          (df['upper_shadow'] < df['body'] * 0.5)).astype(int)
        df['is_shooting_star'] = ((df['upper_shadow'] > df['body'] * 2) & 
                                 (df['lower_shadow'] < df['body'] * 0.5)).astype(int)
        
        # Engulfing patterns (simplified)
        df['prev_body'] = df['body'].shift(1)
        df['is_engulfing'] = ((df['body'] > df['prev_body'] * 1.5) & 
                             (df['is_bullish'] != df['is_bullish'].shift(1))).astype(int)
        
        return df
    
    def generate_trading_signals(self, df):
        """Generate realistic trading signals based on technical analysis"""
        print("🎯 Generating professional trading signals...")
        
        signals = []
        
        for i in range(len(df)):
            signal_score = 0
            
            # RSI signals
            if df.iloc[i]['rsi'] < 30:
                signal_score += 2  # Oversold - buy signal
            elif df.iloc[i]['rsi'] > 70:
                signal_score -= 2  # Overbought - sell signal
            
            # MACD signals
            if df.iloc[i]['macd'] > df.iloc[i]['macd_signal'] and df.iloc[i]['macd'] > 0:
                signal_score += 1.5  # Bullish MACD
            elif df.iloc[i]['macd'] < df.iloc[i]['macd_signal'] and df.iloc[i]['macd'] < 0:
                signal_score -= 1.5  # Bearish MACD
            
            # Bollinger Bands
            if df.iloc[i]['bb_position'] < 0.2:
                signal_score += 1  # Near lower band - buy
            elif df.iloc[i]['bb_position'] > 0.8:
                signal_score -= 1  # Near upper band - sell
            
            # Stochastic
            if df.iloc[i]['stoch_k'] < 20:
                signal_score += 0.5  # Oversold
            elif df.iloc[i]['stoch_k'] > 80:
                signal_score -= 0.5  # Overbought
            
            # Pattern signals
            if df.iloc[i]['is_hammer']:
                signal_score += 1.5  # Hammer - bullish reversal
            if df.iloc[i]['is_shooting_star']:
                signal_score -= 1.5  # Shooting star - bearish reversal
            if df.iloc[i]['is_engulfing']:
                if df.iloc[i]['is_bullish']:
                    signal_score += 1  # Bullish engulfing
                else:
                    signal_score -= 1  # Bearish engulfing
            
            # Moving average signals
            if df.iloc[i]['close'] > df.iloc[i]['sma_20'] and df.iloc[i]['sma_20'] > df.iloc[i]['sma_50']:
                signal_score += 1  # Price above MAs in uptrend
            elif df.iloc[i]['close'] < df.iloc[i]['sma_20'] and df.iloc[i]['sma_20'] < df.iloc[i]['sma_50']:
                signal_score -= 1  # Price below MAs in downtrend
            
            # Volume confirmation
            if df.iloc[i]['volume_ratio'] > 1.5:  # High volume
                if signal_score > 0:
                    signal_score += 0.5  # Volume confirms bullish signal
                elif signal_score < 0:
                    signal_score -= 0.5  # Volume confirms bearish signal
            
            # Convert to classification
            if signal_score >= 2:
                signals.append(2)  # Strong BUY
            elif signal_score >= 1:
                signals.append(1)  # BUY
            elif signal_score <= -2:
                signals.append(-2)  # Strong SELL
            elif signal_score <= -1:
                signals.append(-1)  # SELL
            else:
                signals.append(0)  # HOLD
        
        df['signal'] = signals
        return df
    
    def prepare_training_data(self, df, lookback_window=60):
        """Prepare data for training with proper sequence format"""
        print("🔧 Preparing training data with sequence format...")
        
        # Select feature columns
        feature_columns = [
            'open', 'high', 'low', 'close', 'volume',
            'sma_20', 'sma_50', 'ema_12', 'ema_26',
            'macd', 'macd_signal', 'rsi', 'bb_position',
            'stoch_k', 'stoch_d', 'williams_r', 'cci', 'adx',
            'volume_ratio', 'momentum', 'roc',
            'body', 'upper_shadow', 'lower_shadow',
            'is_bullish', 'is_bearish', 'is_doji',
            'is_hammer', 'is_shooting_star', 'is_engulfing'
        ]
        
        # Remove NaN values
        df_clean = df[feature_columns + ['signal']].dropna()
        
        # Prepare sequences
        X, y = [], []
        
        for i in range(lookback_window, len(df_clean)):
            # Use last 60 candles as input sequence
            sequence = df_clean[feature_columns].iloc[i-lookback_window:i].values
            target = df_clean['signal'].iloc[i]
            
            X.append(sequence)
            y.append(target)
        
        X = np.array(X)
        y = np.array(y)
        
        # Convert signals to classification labels
        # -2: Strong SELL, -1: SELL, 0: HOLD, 1: BUY, 2: Strong BUY
        y_categorical = y + 2  # Shift to 0-4 range
        y_categorical = keras.utils.to_categorical(y_categorical, num_classes=5)
        
        print(f"📊 Training data shape: X={X.shape}, y={y_categorical.shape}")
        
        return X, y_categorical, feature_columns
    
    def build_advanced_model(self, input_shape, num_classes=5):
        """Build advanced LSTM+CNN hybrid model for crypto signal prediction"""
        print("🏗️ Building advanced hybrid model (LSTM + CNN)...")
        
        model = keras.Sequential([
            # CNN layers for pattern recognition
            keras.layers.Conv1D(filters=64, kernel_size=3, activation='relu', input_shape=input_shape),
            keras.layers.Conv1D(filters=64, kernel_size=3, activation='relu'),
            keras.layers.MaxPooling1D(pool_size=2),
            keras.layers.Dropout(0.2),
            
            # LSTM layers for sequence analysis
            keras.layers.LSTM(128, return_sequences=True),
            keras.layers.Dropout(0.3),
            keras.layers.LSTM(64, return_sequences=True),
            keras.layers.Dropout(0.3),
            keras.layers.LSTM(32, return_sequences=False),
            keras.layers.Dropout(0.2),
            
            # Dense layers for final prediction
            keras.layers.Dense(128, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.4),
            keras.layers.Dense(64, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.3),
            keras.layers.Dense(32, activation='relu'),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(num_classes, activation='softmax')
        ])
        
        # Advanced optimizer with learning rate scheduling
        optimizer = keras.optimizers.Adam(
            learning_rate=0.001,
            beta_1=0.9,
            beta_2=0.999,
            epsilon=1e-07
        )
        
        model.compile(
            optimizer=optimizer,
            loss='categorical_crossentropy',
            metrics=['accuracy', 'precision', 'recall']
        )
        
        return model
    
    def train_model(self, X, y, validation_split=0.2):
        """Train the advanced model with professional techniques"""
        print("🚀 Training advanced crypto signal model...")
        
        # Build model
        input_shape = (X.shape[1], X.shape[2])
        model = self.build_advanced_model(input_shape)
        
        # Print model summary
        print("📋 Model Architecture:")
        model.summary()
        
        # Advanced callbacks
        callbacks = [
            keras.callbacks.EarlyStopping(
                monitor='val_accuracy',
                patience=15,
                restore_best_weights=True
            ),
            keras.callbacks.ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=8,
                min_lr=0.0001
            ),
            keras.callbacks.ModelCheckpoint(
                'best_crypto_model.h5',
                monitor='val_accuracy',
                save_best_only=True,
                verbose=1
            )
        ]
        
        # Train model
        history = model.fit(
            X, y,
            epochs=100,
            batch_size=64,
            validation_split=validation_split,
            callbacks=callbacks,
            verbose=1
        )
        
        return model, history
    
    def evaluate_model(self, model, X_test, y_test):
        """Evaluate model performance"""
        print("📊 Evaluating model performance...")
        
        # Get predictions
        y_pred_proba = model.predict(X_test)
        y_pred = np.argmax(y_pred_proba, axis=1)
        y_true = np.argmax(y_test, axis=1)
        
        # Calculate accuracy
        accuracy = accuracy_score(y_true, y_pred)
        
        print(f"🎯 Model Accuracy: {accuracy:.4f}")
        print(f"🎯 Target Accuracy: {self.accuracy_threshold:.4f}")
        
        if accuracy >= self.accuracy_threshold:
            print("✅ Model achieves TradingView-level accuracy!")
        else:
            print("⚠️ Model needs improvement to reach TradingView level")
        
        # Detailed classification report
        signal_labels = ['Strong SELL', 'SELL', 'HOLD', 'BUY', 'Strong BUY']
        report = classification_report(y_true, y_pred, target_names=signal_labels)
        print("📋 Detailed Classification Report:")
        print(report)
        
        return accuracy
    
    def save_model(self, model, filename='advanced_crypto_model.h5'):
        """Save the trained model"""
        model.save(filename)
        print(f"💾 Model saved as {filename}")
    
    def create_tflite_model(self, model, filename='crypto_model.tflite'):
        """Convert model to TensorFlow Lite for Android"""
        print("📱 Converting model to TensorFlow Lite for Android...")
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Save TFLite model
        with open(filename, 'wb') as f:
            f.write(tflite_model)
        
        print(f"📱 TensorFlow Lite model saved as {filename}")
        
    def plot_training_history(self, history):
        """Plot training history"""
        print("📈 Plotting training history...")
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))
        
        # Accuracy plot
        ax1.plot(history.history['accuracy'], label='Training Accuracy')
        ax1.plot(history.history['val_accuracy'], label='Validation Accuracy')
        ax1.set_title('Model Accuracy')
        ax1.set_xlabel('Epoch')
        ax1.set_ylabel('Accuracy')
        ax1.legend()
        ax1.grid(True)
        
        # Loss plot
        ax2.plot(history.history['loss'], label='Training Loss')
        ax2.plot(history.history['val_loss'], label='Validation Loss')
        ax2.set_title('Model Loss')
        ax2.set_xlabel('Epoch')
        ax2.set_ylabel('Loss')
        ax2.legend()
        ax2.grid(True)
        
        plt.tight_layout()
        plt.savefig('training_history.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print("📊 Training history saved as training_history.png")

def main():
    """Main training pipeline"""
    print("🚀 ADVANCED CRYPTO AI TRAINER - WORLD CLASS ACCURACY")
    print("=" * 60)
    
    # Initialize trainer
    trainer = AdvancedCryptoTrainer()
    
    # Generate realistic data
    df = trainer.generate_realistic_crypto_data(num_samples=100000)
    print(f"📊 Generated {len(df)} samples of realistic crypto data")
    
    # Calculate technical indicators
    df = trainer.calculate_technical_indicators(df)
    
    # Create pattern features
    df = trainer.create_pattern_features(df)
    
    # Generate trading signals
    df = trainer.generate_trading_signals(df)
    
    # Prepare training data
    X, y, feature_columns = trainer.prepare_training_data(df, lookback_window=60)
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=np.argmax(y, axis=1)
    )
    
    print(f"📊 Training set: {X_train.shape}")
    print(f"📊 Test set: {X_test.shape}")
    
    # Train model
    model, history = trainer.train_model(X_train, y_train)
    
    # Evaluate model
    accuracy = trainer.evaluate_model(model, X_test, y_test)
    
    # Save model
    trainer.save_model(model, 'advanced_crypto_model.h5')
    
    # Create TFLite model for Android
    trainer.create_tflite_model(model, 'crypto_model.tflite')
    
    # Plot training history
    trainer.plot_training_history(history)
    
    print("\n✅ TRAINING COMPLETE!")
    print("🎯 Your AI model is now ready for deployment!")
    print("📱 TensorFlow Lite model created for Android integration")
    print(f"🏆 Final Accuracy: {accuracy:.4f}")
    
    if accuracy >= trainer.accuracy_threshold:
        print("🌟 CONGRATULATIONS! Your model achieves TradingView-level accuracy!")
    else:
        print("⚡ Consider running more epochs or adding more data for better accuracy")

if __name__ == "__main__":
    main()
