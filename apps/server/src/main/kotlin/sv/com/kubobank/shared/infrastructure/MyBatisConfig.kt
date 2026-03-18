package sv.com.kubobank.shared.infrastructure

import org.apache.ibatis.session.SqlSessionFactory
import org.mybatis.spring.SqlSessionFactoryBean
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.core.io.support.PathMatchingResourcePatternResolver
import javax.sql.DataSource

@Configuration
class MyBatisConfig {
    @Bean
    fun sqlSessionFactory(dataSource: DataSource): SqlSessionFactory {
        val factoryBean = SqlSessionFactoryBean()
        factoryBean.setDataSource(dataSource)
        factoryBean.setMapperLocations(*PathMatchingResourcePatternResolver().getResources("classpath:mybatis/mappers/**/*.xml"))
        //return factoryBean.`object`!!
        // Using the Java getter name directly avoids the 'object' keyword conflict
        return factoryBean.getObject() ?: throw IllegalStateException("MyBatis Factory failed to initialize")
    }
}