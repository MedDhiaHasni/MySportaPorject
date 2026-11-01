'use strict';

const tableName = 'reservations_time_slot_lnk';
const indexName = 'reservations_time_slot_lnk_time_slot_id_unique';

async function hasIndex(connection, client) {
  let result;

  if (client === 'mysql' || client === 'mysql2') {
    result = await connection('information_schema.statistics')
      .count('* as index_count')
      .whereRaw('TABLE_SCHEMA = DATABASE()')
      .where({ TABLE_NAME: tableName, INDEX_NAME: indexName });
  } else if (client === 'pg' || client === 'postgres') {
    result = await connection('pg_indexes')
      .count('* as index_count')
      .whereRaw('schemaname = current_schema()')
      .where({ tablename: tableName, indexname: indexName });
  } else if (client === 'sqlite' || client === 'sqlite3' || client === 'better-sqlite3') {
    result = await connection('sqlite_master')
      .count('* as index_count')
      .where({ type: 'index', tbl_name: tableName, name: indexName });
  } else {
    throw new Error(`Unsupported database client for booking integrity constraint: ${client}`);
  }

  return Number(result[0]?.index_count) > 0;
}

async function ensureReservationSlotUniqueIndex(strapi) {
  const connection = strapi.db.connection;
  const client = connection.client.config.client;

  if (!(await connection.schema.hasTable(tableName))) {
    throw new Error(`Booking integrity table ${tableName} does not exist`);
  }

  const duplicates = await connection(tableName)
    .select('time_slot_id')
    .count('* as reservation_count')
    .whereNotNull('time_slot_id')
    .groupBy('time_slot_id')
    .havingRaw('COUNT(*) > 1');

  if (duplicates.length > 0) {
    const slotIds = duplicates.map((row) => row.time_slot_id).join(', ');
    throw new Error(
      `Cannot enforce unique reservation time slots: duplicate time_slot_id values exist (${slotIds}). Review ${tableName} before retrying.`,
    );
  }

  if (await hasIndex(connection, client)) return;

  await connection.schema.alterTable(tableName, (table) => {
    table.unique(['time_slot_id'], indexName);
  });
  strapi.log.info('[bootstrap] Added unique reservation time-slot constraint');
}

module.exports = { ensureReservationSlotUniqueIndex };
