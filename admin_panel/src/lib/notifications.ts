import prisma from '@/lib/prisma';
import { sendFCMNotification, sendMulticastFCM } from '@/lib/fcm';

export const CITY_AREAS: Record<string, string[]> = {
  madurai: [
    'madurai', 'mattuthavani', 'matuthavani', 'anna nagar', 'simmakkal', 'goripalayam',
    'koodal nagar', 'sellur', 'villapuram', 'thirunagar', 'tirunagar', 'othakadai',
    'otthakadai', 'avaniyapuram', 'thiruparankundram', 'teppakulam', 'arapalayam',
    'ss colony', 's.s. colony', 'ponmeni', 'kalavasal', 'chinthamani', 'melur',
    'vadipatti', 'usilampatti', 'thirumangalam', 'sholavandan', 'alagar kovil',
    'tallakulam', 'narayanapuram', 'bibikulam', 'iyer bungalow', 'pasumalai'
  ],
  dindigul: [
    'dindigul', 'palani', 'kodaikanal', 'natham', 'oddanchatram', 'nilakottai',
    'vedasandur', 'chinnalapatti', 'batlagundu', 'begambur', 'guziliamparai',
    'semanampatti', 'sirumalai', 'reddiarchatram', 'ayyampalayam', 'dindugal'
  ],
  chennai: [
    'chennai', 'madras', 'adyar', 'velachery', 'guindy', 'tambaram', 'chromepet',
    'mylapore', 'porur', 'vadapalani', 'sholinganallur', 'thiruvanmiyur', 'omr', 'ecr',
    'perambur', 'ambattur', 'avadi', 'royapettah', 'triplicane', 'egmore', 'nungambakkam',
    'alwarpet', 'saidapet', 'kilpauk', 'kodambakkam', 'medavakkam', 'royapuram',
    't nagar', 't. nagar', 'besant nagar', 'pallavaram', 'kolathur', 'madipakkam',
    'perungudi', 'thuraipakkam', 'navalur', 'siruseri'
  ],
  coimbatore: [
    'coimbatore', 'kovai', 'gandhipuram', 'rs puram', 'r.s. puram', 'peelamedu',
    'saravanampatti', 'saibaba colony', 'singanallur', 'pollachi', 'mettupalayam',
    'sulur', 'kuniyamuthur', 'thudiyalur', 'kovaipudur', 'race course', 'ganapathy',
    'ondipudur', 'kinathukadavu'
  ],
  tiruchirappalli: [
    'tiruchirappalli', 'tiruchirapalli', 'trichy', 'thillai nagar', 'srirangam',
    'ponmalai', 'golden rock', 'k k nagar', 'kk nagar', 'tiruverumbur', 'bhel',
    'manapparai', 'lalgudi', 'woraiyur', 'cantonment'
  ],
  salem: [
    'salem', 'attur', 'mettur', 'yercaud', 'omalur', 'sankari', 'hasthampatti',
    'shevapet', 'suramangalam', 'ammapet', 'edappadi'
  ],
  tirunelveli: [
    'tirunelveli', 'nellai', 'palayamkottai', 'tenkasi', 'ambasamudram',
    'sankarankovil', 'vallioor', 'vannarpettai', 'thachanallur'
  ],
  erode: [
    'erode', 'bhavani', 'perundurai', 'gobichettipalayam', 'sathyamangalam',
    'anthiyur', 'chithode', 'thindal'
  ],
  tiruppur: [
    'tiruppur', 'tirupur', 'avinashi', 'palladam', 'dharapuram', 'kangeyam',
    'udumalaipettai', 'udumalpet'
  ],
  vellore: [
    'vellore', 'katpadi', 'gudiyatham', 'arcot', 'ranipet', 'walajapet',
    'tirupattur', 'ambur', 'vaniyambadi'
  ],
  thanjavur: [
    'thanjavur', 'tanjore', 'kumbakonam', 'papanasam', 'pattukkottai', 'orathanadu'
  ],
  theni: [
    'theni', 'periyakulam', 'bodinayakanur', 'bodi', 'cumbum', 'uthamapalayam',
    'andipatti', 'chinnamanur'
  ],
  virudhunagar: [
    'virudhunagar', 'sivakasi', 'rajapalayam', 'srivilliputhur', 'aruppukkottai',
    'sattur', 'kariyapatti'
  ],
  sivaganga: [
    'sivaganga', 'karaikudi', 'devakottai', 'manamadurai', 'thiruppuvanam', 'singampunari'
  ],
  ramanathapuram: [
    'ramanathapuram', 'ramnad', 'rameswaram', 'paramakudi', 'kilakarai', 'mudukulathur'
  ],
  kanyakumari: [
    'kanyakumari', 'nagercoil', 'thuckalay', 'marthandam', 'colachel', 'kuzhithurai'
  ],
  namakkal: ['namakkal', 'tiruchengode', 'rasipuram', 'paramathi velur'],
  karur: ['karur', 'kulithalai', 'aravakkurichi', 'velur'],
  cuddalore: ['cuddalore', 'chidambaram', 'panruti', 'vriddhachalam', 'neveli', 'neyveli'],
  villupuram: ['villupuram', 'tindivanam', 'gingee', 'kallakurichi'],
  kanchipuram: ['kanchipuram', 'kancheepuram', 'sriperumbudur', 'chengalpattu', 'walajabad'],
  tiruvallur: ['tiruvallur', 'thiruvallur', 'ponneri', 'gummidipoondi', 'tiruttani'],
  tiruvannamalai: ['tiruvannamalai', 'arani', 'polur', 'chengampattu', 'vandavasi'],
  pudukkottai: ['pudukkottai', 'aranthangi', 'viralimalai'],
  krishnagiri: ['krishnagiri', 'hosur', 'denkanikottai'],
  dharmapuri: ['dharmapuri', 'harur', 'palacode'],
  nilgiris: ['nilgiris', 'ooty', 'udhagamandalam', 'coonoor', 'kotagiri', 'gudalur'],
  bengaluru: ['bengaluru', 'bangalore', 'whitefield', 'koramangala', 'indiranagar', 'electronic city', 'hsr layout']
};

export function extractCity(text: string | null | undefined): string | null {
  if (!text) return null;
  const cleaned = text.toLowerCase().replace(/[\.,\-\/]/g, ' ').replace(/\s+/g, ' ').trim();
  if (!cleaned) return null;

  // 1. Direct match with city names as whole words
  for (const city of Object.keys(CITY_AREAS)) {
    const cityRegex = new RegExp(`\\b${city}\\b`, 'i');
    if (cityRegex.test(cleaned)) {
      return city;
    }
  }

  // 2. Check area names
  for (const [city, areas] of Object.entries(CITY_AREAS)) {
    for (const area of areas) {
      const areaRegex = new RegExp(`\\b${area}\\b`, 'i');
      if (areaRegex.test(cleaned)) {
        return city;
      }
    }
  }

  return null;
}

export function locationsMatch(projLoc: string, provAddr: string | null): boolean {
  if (!provAddr) return true; // If provider hasn't set location, include by default
  const cleanedProj = (projLoc || '').toLowerCase().trim();
  const cleanedProv = (provAddr || '').toLowerCase().trim();

  if (cleanedProj === '' || cleanedProv === '') return true;

  // 1. Statewide or All India providers match all
  if (cleanedProv === 'all india' || cleanedProv === 'tamil nadu' || cleanedProv === 'all tamil nadu') {
    return true;
  }

  // 2. City-level resolution (maps areas like Mattuthavani -> Madurai, Palani -> Dindigul)
  const projCity = extractCity(cleanedProj);
  const provCity = extractCity(cleanedProv);

  if (projCity && provCity) {
    return projCity === provCity;
  }

  // If one side has a detected city and the other contains that city name
  if (projCity && cleanedProv.includes(projCity)) return true;
  if (provCity && cleanedProj.includes(provCity)) return true;

  // 3. Direct contains check
  if (cleanedProv.includes(cleanedProj) || cleanedProj.includes(cleanedProv)) return true;

  // 4. Token word match (ignoring common address descriptors and state names)
  const stopWords = new Set([
    'and', 'the', 'for', 'our', 'new', 'old', 'street', 'road', 'avenue', 'lane',
    'drive', 'court', 'plaza', 'way', 'near', 'opp', 'opposite', 'india', 'tamil', 'nadu',
    'state', 'city', 'district', 'area', 'nagar', 'colony'
  ]);
  const projWords = cleanedProj.split(/[\s,.-]+/).filter(w => w.length > 2 && !stopWords.has(w));
  const provWords = cleanedProv.split(/[\s,.-]+/).filter(w => w.length > 2 && !stopWords.has(w));

  for (const word of projWords) {
    if (provWords.includes(word)) return true;
  }

  return false;
}

/**
 * Standardize any location string to ensure City and State are explicitly present.
 * e.g., "Madurai" -> "Madurai, Tamil Nadu"
 * e.g., "Mattuthavani" -> "Mattuthavani, Madurai, Tamil Nadu"
 */
export function formatCityLocation(loc: string | null | undefined): string {
  if (!loc || !loc.trim()) return 'Madurai, Tamil Nadu';
  const trimmed = loc.trim();
  const city = extractCity(trimmed);
  if (!city) {
    if (!trimmed.toLowerCase().includes('tamil nadu') && !trimmed.toLowerCase().includes('karnataka')) {
      return `${trimmed}, Tamil Nadu`;
    }
    return trimmed;
  }

  // Capitalize detected city name
  const capitalizedCity = city.charAt(0).toUpperCase() + city.slice(1);
  const locLower = trimmed.toLowerCase();

  // If location is already just the city name or city, state
  if (locLower === city || locLower === `${city}, tamil nadu` || locLower === `${city} tamil nadu`) {
    return `${capitalizedCity}, Tamil Nadu`;
  }

  // If the location has an area prefix that doesn't explicitly have the city name (e.g. "Mattuthavani")
  if (!locLower.includes(city)) {
    return `${trimmed}, ${capitalizedCity}, Tamil Nadu`;
  }

  if (!locLower.includes('tamil nadu')) {
    return `${trimmed}, Tamil Nadu`;
  }

  return trimmed;
}

export interface CreateNotificationParams {
  recipientId: string;
  role: 'CONSUMER' | 'PROVIDER';
  title: string;
  body: string;
  type: 'NEW_LEAD' | 'QUOTE_ACCEPTED' | 'TASK_CREATED' | 'TASK_COMPLETED' | 'STAGE_COMPLETED' | 'CHAT_MESSAGE';
  entityId?: string;
  route?: string;
  senderId?: string; // Optional: used for chat notification suppression on device
}

export async function createNotification(params: CreateNotificationParams) {
  try {
    const record = await prisma.notification.create({
      data: {
        recipientId: params.recipientId,
        role: params.role,
        title: params.title,
        body: params.body,
        type: params.type,
        entityId: params.entityId,
        route: params.route,
      },
    });

    // Send instant FCM push notification to phone if recipient has device fcmToken
    (async () => {
      try {
        let fcmToken: string | null = null;
        if (params.role === 'PROVIDER') {
          const prov = await prisma.provider.findUnique({
            where: { id: params.recipientId },
            select: { fcmToken: true },
          });
          fcmToken = prov?.fcmToken ?? null;
        } else {
          const usr = await prisma.user.findUnique({
            where: { id: params.recipientId },
            select: { fcmToken: true },
          });
          fcmToken = usr?.fcmToken ?? null;
        }

        if (fcmToken) {
          await sendFCMNotification({
            token: fcmToken,
            title: params.title,
            body: params.body,
            route: params.route,
            recipientId: params.recipientId,
            role: params.role,
            // Pass senderId so the Flutter FCM listener can suppress the notification
            // when the user is already viewing that specific chat conversation.
            senderId: params.senderId ?? params.entityId,
          });
        }
      } catch (fcmErr) {
        console.error('FCM device push error:', fcmErr);
      }
    })();

    return record;
  } catch (error) {
    console.error('Failed to create notification:', error);
    return null;
  }
}

/**
 * When a consumer creates a new project, notify all verified service providers
 * whose city/location and trade category match the project.
 */
export async function notifyCityProvidersForNewProject(project: {
  id: string;
  title: string;
  type: string;
  location: string;
  budget: number;
}) {
  try {
    const providers = await prisma.provider.findMany({
      where: {
        isVerified: true,
        isRejected: false,
      },
      select: {
        id: true,
        address: true,
        category: true,
        businessName: true,
        fcmToken: true,
      },
    });

    const projectServices = (project.type || '')
      .split(',')
      .map(s => s.trim().toLowerCase())
      .filter(s => s.length > 0);

    const matchingProviders = providers.filter(provider => {
      // 1. Check city / location compatibility
      const locationMatches = locationsMatch(project.location, provider.address);
      if (!locationMatches) return false;

      // 2. Check trade category compatibility
      if (projectServices.length === 0) return true;
      const providerCategories = (provider.category || '')
        .split(',')
        .map(c => c.trim().toLowerCase());

      return projectServices.some(service =>
        providerCategories.some(cat => cat.includes(service) || service.includes(cat))
      );
    });

    if (matchingProviders.length === 0) {
      console.log(`No matching providers found in ${project.location} for services: ${project.type}`);
      return;
    }

    const title = `🏗️ New Project in ${project.location}: ${project.title}`;
    const body = `Client is looking for ${project.type} in ${project.location} (Budget: ₹${project.budget.toLocaleString()}). Tap to submit a quote.`;
    const route = `/provider-lead/${project.id}`;

    // 1. Batch create database notifications
    await prisma.$transaction(
      matchingProviders.map(provider =>
        prisma.notification.create({
          data: {
            recipientId: provider.id,
            role: 'PROVIDER',
            title,
            body,
            type: 'NEW_LEAD',
            entityId: project.id,
            route,
          },
        })
      )
    );

    // 2. Send Multicast FCM Push Notifications to all matching providers' devices
    const fcmTokens = matchingProviders
      .map(p => p.fcmToken)
      .filter((t): t is string => !!t && t.trim().length > 0);

    if (fcmTokens.length > 0) {
      await sendMulticastFCM({
        tokens: fcmTokens,
        title,
        body,
        route,
      });
    }

    console.log(`Successfully notified ${matchingProviders.length} providers in ${project.location} (${fcmTokens.length} closed-phone push notifications dispatched)`);
  } catch (error) {
    console.error('Error notifying city providers for new project:', error);
  }
}

/**
 * When a contractor creates a task on a project, notify the project owner (consumer).
 */
export async function notifyConsumerTaskCreated(params: {
  projectId: string;
  taskTitle: string;
  stage: string;
  duration?: number;
}) {
  try {
    const project = await prisma.project.findUnique({
      where: { id: params.projectId },
      select: { userId: true, title: true },
    });

    if (!project || !project.userId) return;

    await createNotification({
      recipientId: project.userId,
      role: 'CONSUMER',
      title: `📋 New Task Scheduled: ${params.taskTitle}`,
      body: `Added under stage "${params.stage}" on "${project.title}"${params.duration ? ` (Est: ${params.duration} days)` : ''}.`,
      type: 'TASK_CREATED',
      entityId: params.projectId,
      route: `/project-detail/${params.projectId}`,
    });
  } catch (error) {
    console.error('Error notifying consumer of task creation:', error);
  }
}

/**
 * When a task is marked completed, notify the consumer and check if the entire stage is done.
 */
export async function notifyTaskProgressAndMilestones(params: {
  projectId: string;
  taskId: string;
  taskTitle: string;
  stage: string;
  newStatus: string;
}) {
  try {
    const project = await prisma.project.findUnique({
      where: { id: params.projectId },
      include: {
        tasks: true,
        quotes: { where: { isAccepted: true }, select: { providerId: true } },
      },
    });

    if (!project) return;

    const consumerId = project.userId;
    const providerId = project.quotes[0]?.providerId;

    if (params.newStatus === 'Completed') {
      // 1. Notify Consumer of completed task
      await createNotification({
        recipientId: consumerId,
        role: 'CONSUMER',
        title: `✅ Task Finished: ${params.taskTitle}`,
        body: `Milestone finished on "${project.title}" (${params.stage}). Tap to view verification photos and logs.`,
        type: 'TASK_COMPLETED',
        entityId: params.projectId,
        route: `/project-detail/${params.projectId}`,
      });

      // 2. Check if all tasks in this stage are completed
      const stageTasks = project.tasks.filter(
        t => t.stage.toLowerCase().trim() === params.stage.toLowerCase().trim()
      );

      const allStageTasksDone = stageTasks.length > 0 && stageTasks.every(t => 
        t.id === params.taskId ? true : t.status === 'Completed'
      );

      if (allStageTasksDone) {
        // Milestone reached for stage!
        // Notify Consumer
        await createNotification({
          recipientId: consumerId,
          role: 'CONSUMER',
          title: `🎉 Process Completed: ${params.stage}!`,
          body: `All ${stageTasks.length} tasks in stage "${params.stage}" on "${project.title}" are now 100% completed.`,
          type: 'STAGE_COMPLETED',
          entityId: params.projectId,
          route: `/project-detail/${params.projectId}`,
        });

        // Notify Contractor/Provider
        if (providerId) {
          await createNotification({
            recipientId: providerId,
            role: 'PROVIDER',
            title: `🏆 Stage Milestone Achieved: ${params.stage}`,
            body: `Congratulations! All tasks under "${params.stage}" on "${project.title}" are completed.`,
            type: 'STAGE_COMPLETED',
            entityId: params.projectId,
            route: `/provider-job/${params.projectId}`,
          });
        }
      }
    } else if (params.newStatus === 'In Progress') {
      // Notify Consumer that work has started
      await createNotification({
        recipientId: consumerId,
        role: 'CONSUMER',
        title: `⚡ Work Underway: ${params.taskTitle}`,
        body: `Contractor started work on "${params.taskTitle}" (${params.stage}) on "${project.title}".`,
        type: 'TASK_CREATED',
        entityId: params.projectId,
        route: `/project-detail/${params.projectId}`,
      });
    }
  } catch (error) {
    console.error('Error handling task progress notification:', error);
  }
}

/**
 * When a chat message is sent, notify the receiver with the sender's name and message preview.
 * Works for both Consumer→Provider and Provider→Consumer directions.
 */
export async function notifyChatMessage(params: {
  senderId: string;
  receiverId: string;
  text: string;
}) {
  try {
    let senderName = 'Someone';
    let receiverRole: 'CONSUMER' | 'PROVIDER' = 'CONSUMER';
    let chatRoute = '';

    // Resolve sender name
    const senderUser = await prisma.user.findUnique({
      where: { id: params.senderId },
      select: { name: true },
    });
    const senderProvider = await prisma.provider.findUnique({
      where: { id: params.senderId },
      select: { businessName: true, ownerName: true },
    });

    if (senderUser) {
      senderName = senderUser.name || 'Consumer';
    } else if (senderProvider) {
      senderName = senderProvider.businessName || senderProvider.ownerName || 'Provider';
    }

    // Determine receiver role by checking if receiverId is a User or Provider
    const receiverUser = await prisma.user.findUnique({
      where: { id: params.receiverId },
      select: { id: true },
    });

    if (receiverUser) {
      // Receiver is a consumer → sender is a provider
      receiverRole = 'CONSUMER';
      chatRoute = `/chat/${params.senderId}?name=${encodeURIComponent(senderName)}`;
    } else {
      // Receiver is a provider → sender is a consumer
      receiverRole = 'PROVIDER';
      chatRoute = `/provider-chat/${params.senderId}?name=${encodeURIComponent(senderName)}`;
    }

    const preview =
      params.text.length > 60 ? params.text.substring(0, 57) + '…' : params.text;

    await createNotification({
      recipientId: params.receiverId,
      role: receiverRole,
      title: `💬 New message from ${senderName}`,
      body: preview,
      type: 'CHAT_MESSAGE',
      entityId: params.senderId,
      route: chatRoute,
    });
  } catch (error) {
    console.error('Error sending chat message notification:', error);
  }
}
