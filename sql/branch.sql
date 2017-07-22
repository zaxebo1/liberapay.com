ALTER TYPE transfer_context ADD VALUE IF NOT EXISTS 'account-switch';
ALTER TABLE transfers
    DROP CONSTRAINT self_chk,
    ADD CONSTRAINT self_chk CHECK ((tipper <> tippee) = (context <> 'account-switch'));

BEGIN;

    ALTER TABLE transfers
        ADD COLUMN wallet_from text,
        ADD COLUMN wallet_to text;

    UPDATE transfers t
       SET wallet_from = (SELECT p.mangopay_wallet_id FROM participants p WHERE p.id = t.tipper)
         , wallet_to = (SELECT p.mangopay_wallet_id FROM participants p WHERE p.id = t.tippee)
         ;

    ALTER TABLE transfers
        ALTER COLUMN wallet_from SET NOT NULL,
        ALTER COLUMN wallet_to SET NOT NULL,
        ADD CONSTRAINT wallets_chk CHECK (wallet_from <> wallet_to);

    ALTER TABLE exchange_routes ADD COLUMN remote_user_id text;
    UPDATE exchange_routes r SET remote_user_id = (SELECT p.mangopay_user_id FROM participants p WHERE p.id = r.participant);
    ALTER TABLE exchange_routes ALTER COLUMN remote_user_id SET NOT NULL;

    DROP VIEW current_exchange_routes CASCADE;
    CREATE VIEW current_exchange_routes AS
        SELECT DISTINCT ON (participant, network) *
          FROM exchange_routes
      ORDER BY participant, network, id DESC;
    CREATE CAST (current_exchange_routes AS exchange_routes) WITH INOUT;

END;
