import streamlit as st
from snowbook.executor import sql_executor


if "patched" not in st.session_state:
    _old_run = sql_executor.run_single_sql_statement

    def _patched_run_single_sql_statement(*args, **kwargs):
        result = _old_run(*args, **kwargs)
        try:
            result_df = result.query_scan_data_frame
        except Exception:
            return result

        select_exprs = []
        image_columns = {}
        for col, typ in result_df.dtypes:
            if typ == "file":
                select_exprs.append(
                    f"FL_GET_PRESIGNED_URL(CONCAT(FL_GET_STAGE({col}), '/', FL_GET_RELATIVE_PATH({col})), 604800) as {col}"
                )
                image_columns[col] = st.column_config.ImageColumn()
            else:
                select_exprs.append(col)

        if image_columns:
            st.dataframe(result_df.select_expr(", ".join(select_exprs)), column_config=image_columns)
        else:
            return result

    sql_executor.run_single_sql_statement = _patched_run_single_sql_statement
    st.session_state.patched = True


