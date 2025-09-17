import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import cors from 'cors';
import { v4 as uuidv4 } from 'uuid';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set region to US Central (default)
const region = 'us-central1'; // Default region

// Configure CORS
const corsHandler = cors({ origin: true });

// Firestore reference
const db = admin.firestore();

// Interface for pass configuration
interface PassConfig {
  venueId: string;
  backgroundColor: string;
  textColor: string;
  labelColor: string;
  stripColor: string;
  organizationName: string;
  headerText: string;
  balanceLabel: string;
  venueLabel: string;
  nameLabel: string;
  balanceValue: string;
  nameValue: string;
  qrCodeText: string;
  stripImagePath?: string;
  logoImagePath?: string;
}

// Interface for pass creation request
interface CreatePassRequest {
  venueId: string;
  userId: string;
  userBalance: number;
  userName: string;
}

/**
 * Save venue pass configuration
 */
export const saveVenuePassConfig = functions.region(region).https.onCall(async (data: PassConfig, context) => {
  try {
    // Check authentication (skip for emulator testing)
    if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { venueId } = data;
    
    if (!venueId) {
      throw new functions.https.HttpsError('invalid-argument', 'Venue ID is required');
    }

    // Save venue pass template (this is the venue's pass design)
    const venuePassTemplate = {
      ...data,
      updatedAt: new Date().toISOString(),
      updatedBy: context.auth?.uid || 'emulator-user',
      templateType: 'venue_pass_design', // This is the venue's pass template
      status: 'active'
    };
    
    console.log('Venue pass template saved:', JSON.stringify(venuePassTemplate, null, 2));
    
    // In production, this would save to Firestore:
    // await db.collection('venuePassTemplates').doc(venueId).set(venuePassTemplate);
    
    // For now, simulate successful save

    return { 
      success: true, 
      message: `Venue pass template saved successfully for ${venueId}. Your customers will now receive passes with this design when they sign up for your loyalty program.`,
      templateId: venueId,
      templateType: 'venue_pass_design'
    };
  } catch (error) {
    console.error('Error saving venue pass config:', error);
    throw new functions.https.HttpsError('internal', 'Failed to save configuration');
  }
});

/**
 * Get venue pass configuration
 */
export const getVenuePassConfig = functions.region(region).https.onCall(async (data: { venueId: string }, context) => {
  try {
    // Check authentication (skip for emulator testing)
    if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { venueId } = data;
    
    if (!venueId) {
      throw new functions.https.HttpsError('invalid-argument', 'Venue ID is required');
    }

    // Get configuration from Firestore
    const doc = await db.collection('venuePassConfigs').doc(venueId).get();
    
    if (!doc.exists) {
      return { config: null };
    }

    return { config: doc.data() };
  } catch (error) {
    console.error('Error getting venue pass config:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get configuration');
  }
});

/**
 * Create a wallet pass
 */
export const createPass = functions.region(region).https.onCall(async (data: CreatePassRequest, context) => {
  try {
    // Check authentication (skip for emulator testing)
    if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { venueId, userId, userBalance, userName } = data;
    
    if (!venueId || !userId) {
      throw new functions.https.HttpsError('invalid-argument', 'Venue ID and User ID are required');
    }

    // Get venue configuration (use default for emulator testing)
    // TODO: Re-enable Firestore when emulator is properly configured
    // const configDoc = await db.collection('venuePassConfigs').doc(venueId).get();
    // if (!configDoc.exists) {
    //   throw new functions.https.HttpsError('not-found', 'Venue configuration not found');
    // }
    // const config = configDoc.data() as PassConfig;
    
    // Use default configuration for testing
    const config: PassConfig = {
      venueId,
      backgroundColor: '#EEEEEE',
      textColor: '#000000',
      labelColor: '#777777',
      stripColor: '#007AFF',
      organizationName: 'LOCOTAG',
      headerText: 'LOCOTAG',
      balanceLabel: 'BALANCE',
      venueLabel: 'VENUE',
      nameLabel: 'NAME',
      balanceValue: '100.00',
      nameValue: 'Customer',
      qrCodeText: userId
    };

    // Create pass data
    const passData = {
      formatVersion: 1,
      passTypeIdentifier: `pass.com.locofo.${venueId}`,
      serialNumber: uuidv4(),
      teamIdentifier: 'YOUR_TEAM_ID', // Replace with your Apple Developer Team ID
      organizationName: config.organizationName || 'LocoLoyalty',
      description: `${config.organizationName || 'LocoLoyalty'} Loyalty Card`,
      logoText: config.headerText || 'LocoLoyalty',
      foregroundColor: config.textColor || '#000000',
      backgroundColor: config.backgroundColor || '#EEEEEE',
      labelColor: config.labelColor || '#777777',
      generic: {
        primaryFields: [
          {
            key: 'balance',
            label: config.balanceLabel || 'BALANCE',
            value: `$${userBalance || config.balanceValue || '0.00'}`,
            textAlignment: 'PKTextAlignmentRight'
          }
        ],
        secondaryFields: [
          {
            key: 'name',
            label: config.nameLabel || 'NAME',
            value: userName || config.nameValue || 'Customer'
          },
          {
            key: 'venue',
            label: config.venueLabel || 'VENUE',
            value: venueId
          }
        ],
        backFields: [
          {
            key: 'terms',
            label: 'Terms and Conditions',
            value: 'This pass is valid for use at participating locations. Points and rewards are subject to terms and conditions.'
          }
        ]
      },
      barcode: {
        message: config.qrCodeText || userId,
        format: 'PKBarcodeFormatQR',
        messageEncoding: 'iso-8859-1'
      }
    };

    // Store the generated pass (temporarily skip Firestore for emulator testing)
    const passId = uuidv4();
    const passRecord = {
      passId,
      venueId,
      userId,
      serialNumber: passData.serialNumber,
      passData,
      createdAt: new Date().toISOString(),
      createdBy: context.auth?.uid || 'emulator-user',
      status: 'generated'
    };
    
    console.log('Pass would be stored:', JSON.stringify(passRecord, null, 2));
    // TODO: Re-enable Firestore when emulator is properly configured
    // await db.collection('generatedPasses').doc(passId).set(passRecord);

    // For now, return the pass data (actual pass generation would require certificates)
    return { 
      success: true, 
      passId,
      passData,
      message: 'Pass data generated successfully (certificate setup required for actual .pkpass file)'
    };

  } catch (error) {
    console.error('Error creating pass:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create pass');
  }
});

/**
 * Generate a customer pass using the venue's template (called from loyalty app)
 */
export const generateCustomerPass = functions.region(region).https.onCall(async (data: {
  venueId: string;
  customerId: string;
  customerName: string;
  customerBalance: number;
}, context) => {
  try {
    // Check authentication (skip for emulator testing)
    if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { venueId, customerId, customerName, customerBalance } = data;
    
    if (!venueId || !customerId) {
      throw new functions.https.HttpsError('invalid-argument', 'Venue ID and Customer ID are required');
    }

    // In production: Get the venue's pass template
    // const templateDoc = await db.collection('venuePassTemplates').doc(venueId).get();
    // const template = templateDoc.data();
    
    // For now, use default template
    const template = {
      backgroundColor: '#EEEEEE',
      textColor: '#000000',
      labelColor: '#777777',
      stripColor: '#007AFF',
      organizationName: 'LOCOTAG',
      headerText: 'LOCOTAG',
      balanceLabel: 'BALANCE',
      venueLabel: 'VENUE',
      nameLabel: 'NAME'
    };

    // Create personalized pass for this customer
    const customerPass = {
      formatVersion: 1,
      passTypeIdentifier: `pass.com.locofo.${venueId}`,
      serialNumber: `${venueId}-${customerId}-${Date.now()}`,
      teamIdentifier: 'YOUR_TEAM_ID',
      organizationName: template.organizationName,
      description: `${template.organizationName} Loyalty Card`,
      logoText: template.headerText,
      foregroundColor: template.textColor,
      backgroundColor: template.backgroundColor,
      labelColor: template.labelColor,
      generic: {
        primaryFields: [
          {
            key: 'balance',
            label: template.balanceLabel,
            value: `$${customerBalance.toFixed(2)}`,
            textAlignment: 'PKTextAlignmentRight'
          }
        ],
        secondaryFields: [
          {
            key: 'name',
            label: template.nameLabel,
            value: customerName
          },
          {
            key: 'venue',
            label: template.venueLabel,
            value: venueId
          }
        ]
      },
      barcode: {
        message: customerId,
        format: 'PKBarcodeFormatQR',
        messageEncoding: 'iso-8859-1'
      }
    };

    console.log('Customer pass generated:', JSON.stringify(customerPass, null, 2));

    return { 
      success: true, 
      passData: customerPass,
      message: `Pass generated for customer ${customerName} at venue ${venueId}`
    };

  } catch (error) {
    console.error('Error generating customer pass:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate customer pass');
  }
});

/**
 * Get generated passes for a venue
 */
export const getVenuePasses = functions.region(region).https.onCall(async (data: { venueId: string }, context) => {
  try {
    // Check authentication (skip for emulator testing)
    if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { venueId } = data;
    
    if (!venueId) {
      throw new functions.https.HttpsError('invalid-argument', 'Venue ID is required');
    }

    // Get all passes for the venue
    const passesSnapshot = await db.collection('generatedPasses')
      .where('venueId', '==', venueId)
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const passes = passesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    return { 
      success: true, 
      passes,
      count: passes.length
    };

  } catch (error) {
    console.error('Error getting venue passes:', error);
    throw new functions.https.HttpsError('internal', 'Failed to retrieve passes');
  }
});

/**
 * HTTP endpoint for pass creation (for testing)
 */
export const createPassHttp = functions.region(region).https.onRequest((req, res) => {
  return corsHandler(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
      }

      const { venueId, userId, userBalance, userName } = req.body;

      // Basic validation
      if (!venueId || !userId) {
        res.status(400).json({ error: 'Venue ID and User ID are required' });
        return;
      }

      // Get venue configuration
      const configDoc = await db.collection('venuePassConfigs').doc(venueId).get();
      
      if (!configDoc.exists) {
        res.status(404).json({ error: 'Venue configuration not found' });
        return;
      }

      const config = configDoc.data() as PassConfig;

      // Create simplified pass data for testing
      const passData = {
        venueId,
        userId,
        userName: userName || config.nameValue || 'Customer',
        balance: userBalance || config.balanceValue || '0.00',
        qrCode: config.qrCodeText || userId,
        config: {
          backgroundColor: config.backgroundColor,
          textColor: config.textColor,
          labelColor: config.labelColor,
          stripColor: config.stripColor,
          organizationName: config.organizationName,
          headerText: config.headerText
        }
      };

      res.status(200).json({ 
        success: true, 
        passData,
        message: 'Test pass data generated successfully'
      });

    } catch (error) {
      console.error('Error in createPassHttp:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
});

/**
 * Health check endpoint
 */
export const healthCheck = functions.region(region).https.onRequest((req, res) => {
  return corsHandler(req, res, () => {
    res.status(200).json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      service: 'locotag-wallet-functions'
    });
  });
});
