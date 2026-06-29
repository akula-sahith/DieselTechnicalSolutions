import mongoose from 'mongoose';

const connectDB = async () => {
  const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;

  if (!mongoUri) {
    throw new Error('MONGO_URI is not defined in environment variables.');
  }

  await mongoose.connect(mongoUri, {
    autoIndex: true,
  });

  console.log('MongoDB connected successfully.');
};

export default connectDB;
