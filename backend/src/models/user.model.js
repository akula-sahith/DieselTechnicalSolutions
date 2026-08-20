import mongoose from 'mongoose';
import crypto from 'crypto';

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
    },
    role: {
      type: String,
      enum: ['admin', 'reporter'],
      default: 'reporter',
    },
  },
  {
    timestamps: true,
  }
);

userSchema.statics.hashPassword = (password) => {
  return crypto.createHash('sha256').update(password).digest('hex');
};

userSchema.methods.comparePassword = function (candidatePassword) {
  const hashedCandidate = crypto.createHash('sha256').update(candidatePassword).digest('hex');
  return this.password === hashedCandidate;
};

const User = mongoose.model('User', userSchema);

export default User;
