import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# 1. Load dataset gambar
img_size = (64, 64)
batch_size = 32

dataset_path = 'dataset'  # Struktur: dataset/buy, dataset/sell, dataset/hold

train_ds = tf.keras.preprocessing.image_dataset_from_directory(
    dataset_path,
    validation_split=0.2,
    subset="training",
    seed=123,
    image_size=img_size,
    batch_size=batch_size,
    label_mode="categorical"
)
val_ds = tf.keras.preprocessing.image_dataset_from_directory(
    dataset_path,
    validation_split=0.2,
    subset="validation",
    seed=123,
    image_size=img_size,
    batch_size=batch_size,
    label_mode="categorical"
)

# 2. Bangun model CNN sederhana dari NOL
model = keras.Sequential([
    layers.Rescaling(1./255, input_shape=(64, 64, 3)),
    layers.Conv2D(32, 3, activation='relu'),
    layers.MaxPooling2D(),
    layers.Conv2D(64, 3, activation='relu'),
    layers.MaxPooling2D(),
    layers.Flatten(),
    layers.Dense(128, activation='relu'),
    layers.Dense(3, activation='softmax')  # 3 kelas: buy, sell, hold
])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

# 3. Training
model.fit(train_ds, validation_data=val_ds, epochs=10)

# 4. Simpan model ke TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
with open('forex_model.tflite', 'wb') as f:
    f.write(tflite_model)

print('Training selesai! Model TFLite disimpan sebagai forex_model.tflite') 