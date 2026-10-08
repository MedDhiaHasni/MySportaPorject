// @ts-nocheck
'use strict';

const courtService = require('../services/court');

module.exports = {
    async getCourts(ctx) {
        try {
            const managerId = ctx.state.user.managerId;
            const result = await courtService.getManagerCourts(managerId);
            ctx.send(result);
        } catch (error) {
            console.error("Error getCourts:", error.message);
            ctx.badRequest(error.message);
        }
    },

    async getCourt(ctx) {
        try {
            const { id } = ctx.params;
            const managerId = ctx.state.user.managerId;
            const result = await courtService.getCourtById(id, managerId);
            ctx.send(result);
        } catch (error) {
            console.error("Error getCourt:", error.message);
            ctx.badRequest(error.message);
        }
    },

    async createCourt(ctx) {
        try {
            let data = ctx.request.body;
            if (data.data) data = data.data;
            
            const managerId = ctx.state.user.managerId;
            const result = await courtService.createCourt(data, managerId);
            ctx.send({ message: "Court created successfully", court: result });
        } catch (error) {
            console.error("Error createCourt:", error.message);
            ctx.badRequest(error.message);
        }
    },

    async updateCourt(ctx) {
        try {
            const { id } = ctx.params;
            let data = ctx.request.body;
            if (data.data) data = data.data;
            
            const managerId = ctx.state.user.managerId;
            const result = await courtService.updateCourt(id, managerId, data);
            ctx.send({ message: "Court updated successfully", court: result });
        } catch (error) {
            console.error("Error updateCourt:", error.message);
            ctx.badRequest(error.message);
        }
    },

    async deleteCourt(ctx) {
        try {
            const { id } = ctx.params;
            const managerId = ctx.state.user.managerId;
            const result = await courtService.deleteCourt(id, managerId);
            ctx.send(result);
        } catch (error) {
            console.error("Error deleteCourt:", error.message);
            ctx.badRequest(error.message);
        }
    },
    
    // kif kif backup hadhouma lelli 9balhom
    // Assign worker to court 
    async assignWorker(ctx) {
        try {
            const { id } = ctx.params;
            const { workerId } = ctx.request.body;
            const managerId = ctx.state.user.managerId;
            
            if (!workerId) {
                return ctx.badRequest("workerId is required");
            }
            
            const result = await courtService.assignWorkerToCourt(id, workerId, managerId);
            ctx.send(result);
        } catch (error) {
            console.error("Error assignWorker:", error.message);
            ctx.badRequest(error.message);
        }
    },
    
    // Remove worker from court
    async removeWorker(ctx) {
        try {
            const { id } = ctx.params;
            const managerId = ctx.state.user.managerId;
            
            const result = await courtService.removeWorkerFromCourt(id, managerId);
            ctx.send(result);
        } catch (error) {
            console.error("Error removeWorker:", error.message);
            ctx.badRequest(error.message);
        }
    }
};

