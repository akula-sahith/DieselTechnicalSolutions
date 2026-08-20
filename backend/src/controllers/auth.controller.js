import User from '../models/user.model.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return sendError(res, 'Email and password are required.', {}, 400);
    }

    const cleanEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: cleanEmail });

    if (!user) {
      return sendError(res, 'Invalid credentials. User not found.', {}, 401);
    }

    if (!user.comparePassword(password)) {
      return sendError(res, 'Invalid credentials. Password incorrect.', {}, 401);
    }

    const userPayload = {
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
    };

    return sendSuccess(res, 'Login successful.', { user: userPayload });
  } catch (error) {
    return sendError(res, 'Login failed.', { details: error.message }, 500);
  }
};

export const registerReporter = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return sendError(res, 'Name, email, and password are required.', {}, 400);
    }

    const cleanEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({ email: cleanEmail });
    if (existingUser) {
      return sendError(res, 'A user with this email already exists.', {}, 400);
    }

    const hashedPassword = User.hashPassword(password);
    const reporter = await User.create({
      name: name.trim(),
      email: cleanEmail,
      password: hashedPassword,
      role: 'reporter',
    });

    const responseUser = {
      id: reporter._id,
      name: reporter.name,
      email: reporter.email,
      role: reporter.role,
      createdAt: reporter.createdAt,
    };

    return sendSuccess(res, 'Reporter credentials created successfully.', responseUser, 201);
  } catch (error) {
    return sendError(res, 'Failed to create reporter credentials.', { details: error.message }, 500);
  }
};

export const getReporters = async (req, res) => {
  try {
    const reporters = await User.find({ role: 'reporter' })
      .select('-password')
      .sort({ createdAt: -1 });

    return sendSuccess(res, 'Reporters retrieved successfully.', { reporters });
  } catch (error) {
    return sendError(res, 'Failed to fetch reporters.', { details: error.message }, 500);
  }
};

export const deleteReporter = async (req, res) => {
  try {
    const reporter = await User.findOneAndDelete({ _id: req.params.id, role: 'reporter' });
    if (!reporter) {
      return sendError(res, 'Reporter not found.', {}, 404);
    }

    return sendSuccess(res, 'Reporter deleted successfully.', {});
  } catch (error) {
    return sendError(res, 'Failed to delete reporter.', { details: error.message }, 500);
  }
};

export const seedDefaultUsers = async () => {
  try {
    // Seed default admin
    const adminEmail = 'admin@dts.com';
    const adminExists = await User.findOne({ email: adminEmail });
    if (!adminExists) {
      await User.create({
        name: 'Admin Siva',
        email: adminEmail,
        password: User.hashPassword('Password123!'),
        role: 'admin',
      });
      console.log('[Auth Seed] Default Admin user created: admin@dts.com');
    }

    // Seed default reporter
    const reporterEmail = 'siva@dts.com';
    const reporterExists = await User.findOne({ email: reporterEmail });
    if (!reporterExists) {
      await User.create({
        name: 'Technician Siva',
        email: reporterEmail,
        password: User.hashPassword('Password123!'),
        role: 'reporter',
      });
      console.log('[Auth Seed] Default Reporter user created: siva@dts.com');
    }
  } catch (error) {
    console.error('[Auth Seed] Error seeding default users:', error?.message || error);
  }
};
