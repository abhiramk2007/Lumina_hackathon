import { signUp, signIn, signOut, getCurrentUser } from 'aws-amplify/auth';

export const MockCognito = {
  // Now using real AWS Cognito via Amplify v6
  register: async (email, password) => {
    try {
      const { isSignUpComplete, userId, nextStep } = await signUp({
        username: email,
        password,
        options: {
          userAttributes: {
            email,
          },
        }
      });
      console.log('AWS Cognito Register:', userId);
      // Note: Cognito requires email verification by default.
      // If auto-confirm is not setup, the user will be unconfirmed.
      return { success: true, message: 'User registered in AWS Cognito. Check email for verification code if required.' };
    } catch (error) {
      console.error('AWS Cognito Register Error:', error);
      throw error;
    }
  },

  login: async (email, password) => {
    try {
      const { isSignedIn, nextStep } = await signIn({ username: email, password });
      if (isSignedIn) {
        return { email, token: 'aws-cognito-session-active' };
      }
      throw new Error('Sign in not complete. Next step: ' + nextStep.signInStep);
    } catch (error) {
      if (error.name === 'UserAlreadyAuthenticatedException') {
        // Handle gracefully if a session is already active
        return { email, token: 'aws-cognito-session-active' };
      }
      console.error('AWS Cognito Login Error:', error);
      throw error;
    }
  },

  logout: async () => {
    try {
      await signOut();
      return { success: true };
    } catch (error) {
      console.error('AWS Cognito Logout Error:', error);
      throw error;
    }
  },

  getSession: async () => {
    try {
      const { username, userId } = await getCurrentUser();
      return { email: username, token: userId };
    } catch (error) {
      // Not signed in
      return null;
    }
  }
};
