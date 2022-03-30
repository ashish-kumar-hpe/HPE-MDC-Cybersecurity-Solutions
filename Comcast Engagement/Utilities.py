************************************************************************************************************************************************************************
#Utility function to execute query
def run_query(query, table_name = "answers", drop_answer_table=True, show_query=False):
    if drop_answer_table:
        conn.drop_frame(table_name)
    if query[-1] != '\n':
        query += '\n'
    query += 'INTO {}'.format(table_name)
    if show_query:
        print("Query:\n" + query)
    job = conn.schedule_job(query)
    print("Launched job {}".format(job.id))
    conn.wait_for_job(job)
    table = conn.get_table_frame(table_name)
    return table
    
************************************************************************************************************************************************************************ 
# retrieve the answer rows to the client in a pandas frame
print("Print preview NetworkEvent data....")

Query_Print_Preview_Data = """
MATCH (n1:RemoteIP)-[edge:NetworkEvent]->(n2:EmailServer) 
RETURN edge.timestamp,
	edge.hostname,
	edge.service,
	edge.protocol,
	edge.action_0,
	edge.error_0,
	edge.reason_0,
	edge.user,
	edge.lip,
	edge.port,
	edge.remote,
	edge.session,
	edge.method,
	edge.policy_code,
	edge.TLSVersion,
	edge.TLS_handshaking,
	edge.edge.ssl_command,
	edge.ssl_info_0,
	edge.ssl_info_1,
	edge.disconnected,
	edge.disconnected_by,
	edge.in,
	edge.out,
	edge.out_suffix,
	edge.size,
	edge.n_successful_auths,
	edge.n_attempts,
	edge.n_secs_duration,
	edge.connection_reset_by,
	edge.permissions,
	edge.blocklist,
	edge.blacklist,
	edge.secured
"""
data = run_query(Query_Print_Preview_Data)
print('Number of answers: {:,}'.format(data.get_data()[0][0]))

data1 = data.get_data_pandas()
data2 = data.drop_duplicates()
data2[0:50]

************************************************************************************************************************************************************************
# retrieve the answer rows to the client in a pandas frame
print("Print preview WForce data....")

Query_Print_Preview_Data = """
MATCH (n1:RemoteIP)-[edge:WForce]->(n2:EmailServer) 
RETURN edge.timestamp,
	edge.hostname,
	edge.wforce_pid,
	edge.tag,
	edge.policy,
	edge.allow,
	edge.remote,
	edge.user,
	edge.session,
	edge.protocol,
	edge.countries,
	edge.policy_reject,
	edge.session_id,
	edge.tls,
	edge.success,
	edge.pwhash,
	edge.bl_ip,
	edge.bl_mask,
	edge.dest,
	edge.result,
	edge.expire_secs,
	edge.reason,
	edge.ttl,
	edge.device_id,
	edge.device_attrs_imapc_family,
	edge.device_attrs_imapc_major,
	edge.device_attrs_imapc_minor,
	edge.device_attrs_os_family,
	edge.device_attrs_os_major,
	edge.device_attrs_os_minor,
	edge.rattrs_rbl_zone,
	edge.rattrs_nl,
	edge.rattrs_wl,
	edge.rattrs_policy_code,
	edge.rattrs_policy,
	edge.rattrs_dgl,
	edge.rattrs_diff_failpass,
	edge.rattrs_threshold,
	edge.rattrs_diff_logins,
	edge.rattrs_action,
	edge.rattrs_bl_expiry,
	edge.rattrs_blacklisted,
	edge.rattrs_bl_key,
	edge.rattrs_wl_key,
	edge.rattrs_failed_login_percent,
	edge.rattrs_tarpit,
	edge.rattrs_n_attempts
"""
data = run_query(Query_Print_Preview_Data)
print('Number of answers: {:,}'.format(data.get_data()[0][0]))

data1 = data.get_data_pandas()
data2 = data.drop_duplicates()
data2[0:50]
************************************************************************************************************************************************************************
