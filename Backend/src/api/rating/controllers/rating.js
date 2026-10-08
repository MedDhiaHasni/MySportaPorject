// src/api/rating/controllers/rating.js
// @ts-nocheck
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::rating.rating', ({ strapi }) => ({

   
  async submitRating(ctx) {
    try {
      const user = ctx.state.user;
      if (user?.user_role !== 'player') {
        return ctx.forbidden('Only players can rate venues');
      }

      // Get player profile
      const player = await strapi.db.query('api::player.player').findOne({
        where: { player: user.id },
      });
      if (!player) {
        return ctx.badRequest('Player profile not found');
      }

      let requestData = ctx.request.body;
      if (requestData.data) requestData = requestData.data;

      const { rating_value, venue_id } = requestData;

      if (!rating_value || !venue_id) {
        return ctx.badRequest('rating_value and venue_id are required');
      }

      // Validate rating range hedhi just securité khw 5ater betbi3etha ya5tar int
      if (rating_value < 0.5 || rating_value > 5) {
        return ctx.badRequest('Rating must be between 0.5 and 5');
      }

     // checki player cofirma wela completa reservation bech ynajem yrati
      
      // First, get all courts that belong to this venue
      const venueCourts = await strapi.db.query('api::court.court').findMany({
        where: { venue: venue_id },
        select: ['id'],
      });
      
      const courtIds = venueCourts.map(court => court.id);
      
      if (courtIds.length === 0) {
        return ctx.badRequest('Venue has no courts');
      }
      
      // Check lahnee
      const hasCompletedReservation = await strapi.db.query('api::reservation.reservation').findOne({
        where: {
          player: player.id,
          booking_status: { $in: ['confirmed', 'completed'] },
          court: { $in: courtIds },
        },
      });
      
      if (!hasCompletedReservation) {
        return ctx.forbidden('You can only rate venues where you have a confirmed or completed reservation');
      }

      // Check if rating already exists
      const existingRating = await strapi.db.query('api::rating.rating').findOne({
        where: {
          player: player.id,
          venue: venue_id,
        },
      });

      let rating;
      let isUpdate = false;

      if (existingRating) {
        // Update existing rating
        rating = await strapi.db.query('api::rating.rating').update({
          where: { id: existingRating.id },
          data: {
            rating_value: rating_value,
          },
        });
        isUpdate = true;
      } else {
        // Create new rating
        rating = await strapi.db.query('api::rating.rating').create({
          data: {
            rating_value: rating_value,
            player: player.id,
            venue: venue_id,
          },
        });
      }

      // el avg rating mta3 el complex zeda yetbadel
      await _updateVenueRating(venue_id);

      return ctx.send({
        success: true,
        message: isUpdate ? 'Rating updated successfully' : 'Rating submitted successfully',
        rating: rating,
      });

    } catch (error) {
      console.error('Error submitRating:', error);
      return ctx.badRequest(error.message);
    }
  },

  
  // DELETE rating
  
  async deleteRating(ctx) {
    try {
      const user = ctx.state.user;
      if (user?.user_role !== 'player') {
        return ctx.forbidden('Only players can delete ratings');
      }

      const { id } = ctx.params;

      const player = await strapi.db.query('api::player.player').findOne({
        where: { player: user.id },
      });
      if (!player) {
        return ctx.badRequest('Player profile not found');
      }

      
      const rating = await strapi.db.query('api::rating.rating').findOne({
        where: { id: parseInt(id) },
      });

      if (!rating) {
        return ctx.notFound('Rating not found');
      }

      // Verify ownership lel securité kel3ada
      if (rating.player !== player.id) {
        return ctx.forbidden('You can only delete your own ratings');
      }

      const venueId = rating.venue;

     
      await strapi.db.query('api::rating.rating').delete({
        where: { id: parseInt(id) },
      });

     // el rating mta3 el complex zeda yetbadel ba3d ma yetsupprimi
      await _updateVenueRating(venueId);

      return ctx.send({
        success: true,
        message: 'Rating deleted successfully',
      });

    } catch (error) {
      console.error('Error deleteRating:', error);
      return ctx.badRequest(error.message);
    }
  },

  // 
  // GET player's rating for a specific complex
  
  async getUserRating(ctx) {
    try {
      const user = ctx.state.user;
      if (user?.user_role !== 'player') {
        return ctx.forbidden('Only players can access this');
      }

      const { venueId } = ctx.params;

      // Get player profile
      const player = await strapi.db.query('api::player.player').findOne({
        where: { player: user.id },
      });
      if (!player) {
        return ctx.send({ rating: null });
      }

      const rating = await strapi.db.query('api::rating.rating').findOne({
        where: {
          player: player.id,
          venue: parseInt(venueId),
        },
      });

      return ctx.send({
        rating: rating || null,
      });

    } catch (error) {
      console.error('Error getUserRating:', error);
      return ctx.send({ rating: null });
    }
  },

   
  // t5arej ratings el kol for a specefic complex 
  
  async getVenueRatings(ctx) {
    try {
      const { venueId } = ctx.params;

      const ratings = await strapi.db.query('api::rating.rating').findMany({
        where: { venue: parseInt(venueId) },
        populate: {
          player: {
            populate: ['player'] // Get user info for player name
          }
        },
        orderBy: { createdAt: 'desc' },
      });

      // Transform to include player name
      const transformedRatings = [];
      for (const rating of ratings) {
        let playerName = 'Anonymous';
        let playerAvatar = null;
        
        if (rating.player) {
          // Try to get user info from the player relation
          const user = await strapi.db.query('plugin::users-permissions.user').findOne({
            where: { id: rating.player.player },
          });
          if (user) {
            playerName = user.username || 'Player';
          } else if (rating.player.nom) {
            playerName = rating.player.nom;
          }
        }

        transformedRatings.push({
          id: rating.id,
          rating_value: rating.rating_value,
          player_name: playerName,
          created_at: rating.createdAt,
        });
      }

      return ctx.send({
        ratings: transformedRatings,
        count: transformedRatings.length,
      });

    } catch (error) {
      console.error('Error getVenueRatings:', error);
      return ctx.badRequest(error.message);
    }
  },
}));

// ne7seb el complex avg rating
async function _updateVenueRating(venueId) {
  try {
    // Get all ratings for this venue
    const ratings = await strapi.db.query('api::rating.rating').findMany({
      where: { venue: venueId },
    });

    const totalRatings = ratings.length;
    let sum = 0;

    for (const rating of ratings) {
      sum += rating.rating_value;
    }

    const averageRating = totalRatings > 0 ? sum / totalRatings : 0;

    
    await strapi.db.query('api::venue.venue').update({
      where: { id: venueId },
      data: {
        avg_rating: parseFloat(averageRating.toFixed(1)),
        total_rating: totalRatings,
      },
    });

    console.log(`[rating] Updated venue ${venueId}: avg=${averageRating.toFixed(1)}, total=${totalRatings}`);
  } catch (error) {
    console.error('Error _updateVenueRating:', error);
  }
}