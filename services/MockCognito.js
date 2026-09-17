import AsyncStorage from '@react-native-async-storage/async-storage';

const USERS_KEY = '@mock_cognito_users';
const SESSION_KEY = '@mock_cognito_session';

export const MockCognito = {
  // Simulate Cognito Register
  register: async (email, password) => {
    try {
      const usersStr = await AsyncStorage.getItem(USERS_KEY);
      const users = usersStr ? JSON.parse(usersStr) : [];
      
      if (users.find(u => u.email === email)) {
        throw new Error('User already exists');
      }

      users.push({ email, password }); // In a real app, passwords are never stored plain-text!
      await AsyncStorage.setItem(USERS_KEY, JSON.stringify(users));
      return { success: true, message: 'User registered successfully' };
    } catch (error) {
      throw error;
    }
  },

  // Simulate Cognito Login
  login: async (email, password) => {
    try {
      const usersStr = await AsyncStorage.getItem(USERS_KEY);
      const users = usersStr ? JSON.parse(usersStr) : [];
      
      const user = users.find(u => u.email === email && u.password === password);
      if (!user) {
        throw new Error('Invalid email or password');
      }

      // Generate a fake JWT token / session
      const session = {
        token: `mock-jwt-token-${Date.now()}`,
        email: user.email
      };
      
      await AsyncStorage.setItem(SESSION_KEY, JSON.stringify(session));
      return session;
    } catch (error) {
      throw error;
    }
  },

  // Simulate Cognito Logout
  logout: async () => {
    try {
      await AsyncStorage.removeItem(SESSION_KEY);
      return { success: true };
    } catch (error) {
      throw error;
    }
  },

  // Check if user is authenticated
  getSession: async () => {
    try {
      const sessionStr = await AsyncStorage.getItem(SESSION_KEY);
      return sessionStr ? JSON.parse(sessionStr) : null;
    } catch (error) {
      return null;
    }
  }
};
